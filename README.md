# TODO Application with MongoDB and Vue.js
This is a simple TODO application with a MongoDB backend and a front-end built using Vue.js. It allows you to create, read, update, and delete tasks with optional deadlines.
# Features
1. Create tasks with titles and optional deadlines.
2. Mark tasks as completed or incomplete.
3. Edit existing tasks.
4. Delete tasks.
5. List all tasks with their deadlines.
# Prerequisites
Before you begin, ensure you have met the following requirements:
1. Go programming language installed.
2. MongoDB installed and running.
3. Basic knowledge of Go and Vue.js.
# Installation
1. Clone the repository to your local machine:
git clone https://github.com/bakhtybayevn/todo.git
2. Navigate to the project directory:
cd todo-app
3. Install the required Go packages:
go get -u github.com/go-chi/chi
go get -u github.com/go-chi/chi/middleware
go get -u github.com/go-playground/validator/v10
go get -u github.com/thedevsaddam/renderer
go get -u gopkg.in/mgo.v2
go get -u gopkg.in/mgo.v2/bson
4. Run the Go server:
go run main.go
The server will start and listen on port 9000 by default. You can change the port in the main.go file.
5. Open your web browser and go to http://localhost:9000 to access the TODO application.
# Usage
1. To create a new task, enter a task title and an optional deadline, and click the "Add" button.
2. To mark a task as completed or incomplete, click the circle icon next to the task.
3. To edit a task, click the "Edit" button next to the task, make your changes, and click the "Save" button.
4. To delete a task, click the "Delete" button next to the task.
# Acknowledgments
Thanks to the authors of the libraries used in this project.
4. humidity: The relative humidity.
5. description: A description of the weather conditions.
# Contributing
Feel free to contribute to this project by opening issues, suggesting improvements, or submitting pull requests.
