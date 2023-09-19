package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"time"

	"github.com/go-chi/chi"
	"github.com/go-chi/chi/middleware"
	"github.com/go-playground/validator/v10"
	"github.com/thedevsaddam/renderer"
	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const (
	port            = ":9000"
	readTimeout     = 60 * time.Second
	writeTimeout    = 60 * time.Second
	idleTimeout     = 60 * time.Second
	shutdownTimeout = 5 * time.Second
)

var (
	rnd            *renderer.Render
	db             *mgo.Database
	hostName       = "localhost:27017"
	dbName         = "demo_todo"
	collectionName = "todo"
)

func init() {
	rnd = renderer.New()
	sess, err := mgo.Dial(hostName)
	if err != nil {
		log.Fatalf("Failed to connect to the database: %s\n", err)
	}
	sess.SetMode(mgo.Monotonic, true)
	db = sess.DB(dbName)
}

type (
	todoModel struct {
		ID        bson.ObjectId `bson:"_id,omitempty"`
		Title     string        `bson:"title"`
		Completed bool          `bson:"completed"`
		Deadline  time.Time     `bson:"deadline"`
		CreatedAt time.Time     `bson:"createAt"`
	}

	todo struct {
		ID        string    `json:"id"`
		Title     string    `json:"title" validate:"required"`
		Completed bool      `json:"completed"`
		Deadline  time.Time `json:"deadline"`
		CreatedAt time.Time `json:"created_at"`
	}
)

func main() {
	stopChan := make(chan os.Signal)
	signal.Notify(stopChan, os.Interrupt)

	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Get("/", homeHandler)

	r.Mount("/todo", todoRouter())

	srv := &http.Server{
		Addr:         port,
		Handler:      r,
		ReadTimeout:  readTimeout,
		WriteTimeout: writeTimeout,
		IdleTimeout:  idleTimeout,
	}

	go func() {
		log.Println("Listening on port", port)
		if err := srv.ListenAndServe(); err != nil {
			log.Printf("listen: %s\n", err)
		}
	}()

	<-stopChan
	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server shutdown error: %s\n", err)
	}
	log.Println("Server gracefully stopped!")
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
	err := rnd.Template(w, http.StatusOK, []string{"static/home.tpl"}, nil)
	if err != nil {
		renderError(w, http.StatusInternalServerError, err.Error(), err)
	}
}

func createTodo(w http.ResponseWriter, r *http.Request) {
	var t todo

	if err := json.NewDecoder(r.Body).Decode(&t); err != nil {
		renderError(w, http.StatusProcessing, "Failed to decode JSON", err)
		return
	}

	// Use the validateTodo function for validation
	if err := validateTodo(t); err != nil {
		renderValidationError(w, err.Error())
		return
	}

	tm := todoModel{
		ID:        bson.NewObjectId(),
		Title:     t.Title,
		Completed: false,
		Deadline:  t.Deadline, // Include the deadline
		CreatedAt: time.Now(),
	}
	if err := db.C(collectionName).Insert(&tm); err != nil {
		renderError(w, http.StatusProcessing, "Failed to save todo", err)
		return
	}

	renderJSON(w, http.StatusCreated, map[string]interface{}{
		"message": "Todo created successfully",
		"todo_id": tm.ID.Hex(),
	})
}

func updateTodo(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimSpace(chi.URLParam(r, "id"))

	if !bson.IsObjectIdHex(id) {
		renderValidationError(w, "The id is invalid")
		return
	}

	var t todo

	if err := json.NewDecoder(r.Body).Decode(&t); err != nil {
		renderError(w, http.StatusProcessing, "Failed to decode JSON", err)
		return
	}

	// Use the validateTodo function for validation
	if err := validateTodo(t); err != nil {
		renderValidationError(w, err.Error())
		return
	}

	if err := db.C(collectionName).
		Update(
			bson.M{"_id": bson.ObjectIdHex(id)},
			bson.M{"title": t.Title, "completed": t.Completed, "deadline": t.Deadline},
		); err != nil {
		renderError(w, http.StatusProcessing, "Failed to update todo", err)
		return
	}

	renderJSON(w, http.StatusOK, map[string]interface{}{
		"message": "Todo updated successfully",
	})
}

func fetchTodos(w http.ResponseWriter, r *http.Request) {
	todos := []todoModel{}

	if err := db.C(collectionName).
		Find(bson.M{}).
		All(&todos); err != nil {
		renderError(w, http.StatusProcessing, "Failed to fetch todo", err)
		return
	}

	todoList := []todo{}
	for _, t := range todos {
		todoList = append(todoList, todo{
			ID:        t.ID.Hex(),
			Title:     t.Title,
			Completed: t.Completed,
			Deadline:  t.Deadline, // Include the deadline
			CreatedAt: t.CreatedAt,
		})
	}

	renderJSON(w, http.StatusOK, map[string]interface{}{
		"data": todoList,
	})
}

func deleteTodo(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimSpace(chi.URLParam(r, "id"))

	if !bson.IsObjectIdHex(id) {
		renderValidationError(w, "The id is invalid")
		return
	}

	if err := db.C(collectionName).RemoveId(bson.ObjectIdHex(id)); err != nil {
		renderError(w, http.StatusProcessing, "Failed to delete todo", err)
		return
	}

	renderJSON(w, http.StatusOK, map[string]interface{}{
		"message": "Todo deleted successfully",
	})
}

func renderJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(data); err != nil {
		log.Printf("JSON encoding error: %s\n", err)
	}
}

func renderError(w http.ResponseWriter, status int, message string, err error) {
	log.Printf("Error: %s\n", message)
	renderJSON(w, status, map[string]interface{}{
		"message": message,
	})
}

func renderValidationError(w http.ResponseWriter, message string) {
	renderJSON(w, http.StatusBadRequest, map[string]interface{}{
		"message": message,
	})
}

func validateTodo(t todo) error {
	validate := validator.New()
	if err := validate.Struct(t); err != nil {
		return err
	}
	return nil
}

func todoRouter() http.Handler {
	rg := chi.NewRouter()
	rg.Group(func(r chi.Router) {
		r.Get("/", fetchTodos)
		r.Post("/", createTodo)
		r.Put("/{id}", updateTodo)
		r.Delete("/{id}", deleteTodo)
	})
	return rg
}
