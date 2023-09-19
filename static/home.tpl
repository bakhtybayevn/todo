<!DOCTYPE html>
<html lang="en">
<head>
    <title>Todo</title>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <script src="https://unpkg.com/vue@2.6.14"></script>
    <script src="https://cdn.jsdelivr.net/npm/vue-resource@1.5.1"></script>
    <!-- Bootstrap CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css">
    <style type="text/css">
        .del {
            text-decoration: line-through;
        }
        .card {
            border-radius: 10px;
            border: none;
        }
        .card-body {
            padding: 0 !important;
        }
        .todo-title {
            width: 100%;
            background: #4CAF50;
            color: #FFF;
            font-size: 30px;
            font-weight: bold;
            padding: 20px 10px;
            text-align: center;
            border-top-left-radius: 10px;
            border-top-right-radius: 10px;
        }
        .custom-input {
            border-radius: 0 !important;
            padding: 10px 10px !important;
            border-bottom: none;
        }
        .custom-input:focus, .custom-input:active {
            box-shadow: none !important;
        }
        .custom-button {
            border-radius: 0 !important;
            cursor: pointer;
        }
        .custom-button:focus, .custom-button:active {
            box-shadow: none !important;
        }
        .list-group li {
            cursor: pointer;
            border-radius: 0 !important;
        }
        .checked {
            background: #3498db;
            color: #fff;
        }
        .error {
            border: 2px solid #e74c3c !important;
        }
        .not-checked {
            background: #2ecc71;
            color: #fff;
            font-weight: bold;
        }
    </style>
</head>
<body>
<div class="container" id="root">
    <div class="row">
        <div class="col-6 offset-3">
            <br><br>
            <div class="card">
                <div class="todo-title">
                    Daily Todo Lists
                </div>
                <div class="card-body">
                    <form v-on:submit.prevent>
                        <div class="input-group">
                            <input type="text" v-model="todo.title" v-on:keyup="checkForEnter($event)"
                                   class="form-control custom-input" :class="{ 'error': showError }"
                                   placeholder="Add your todo">
                            <span class="input-group-btn">
                            <button class="btn custom-button" :class="{'btn-success' : !enableEdit, 'btn-warning' : enableEdit}"
                                    type="button" v-on:click="addTodo"><span
                                    :class="{'fa fa-plus' : !enableEdit, 'fa fa-edit' : enableEdit}"></span></button>
                        </span>
                        </div>
                    </form>
                    <ul class="list-group">
                        <li class="list-group-item"
                            :class="{ 'checked': todo.completed, 'not-checked': !todo.completed }"
                            v-for="(todo, todoIndex) in todos" v-on:click="toggleTodo(todo, todoIndex)">
                            <i :class="{'fa fa-circle': !todo.completed, 'fa fa-check-circle text-success': todo.completed }">&nbsp;</i>
                            <span :class="{ 'del': todo.completed }">@{ todo.title }</span>
                            <div class="btn-group float-right" role="group" aria-label="Basic example">
                                <button type="button" class="btn btn-success btn-sm custom-button"
                                        v-on:click.prevent.stop v-on:click="editTodo(todo, todoIndex)"><span
                                        class="fa fa-edit"></span></button>
                                <button type="button" class="btn btn-danger btn-sm custom-button"
                                        v-on:click.prevent.stop v-on:click="deleteTodo(todo, todoIndex)"><span
                                        class="fa fa-trash"></span></button>
                            </div>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</div>
<!-- Optional JavaScript -->
<!-- jQuery first, then Popper.js, then Bootstrap JS -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"
        integrity="sha384-KyZXEAg3QhqLMpG8r+Jtnzl7f5Oq6brU5G5Gz1Z5Yxg5z5cD7+j5Bbf5x5a0fd5w5"
        crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/2.9.2/umd/popper.min.js"
        integrity="sha384-w1Vbx4mz0Hs6z5B5n5n5n5RB5V5bf5O5/5V5V5v5E5m5z5P5V5P5f5I5Q5I5Y5Y5O5f5"
        crossorigin="anonymous"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"
        integrity="sha384-pzjw8f+ua8nE5okbf7kMC5Fz5w5Y5a5u5u5u5a5u5u5u5u5O5u5u5u5u5u5u5u5u5u5f5"
        crossorigin="anonymous"></script>
<script type="text/javascript">
    var Vue = new Vue({
        el: '#root',
        delimiters: ['@{', '}'],
        data: {
            showError: false,
            enableEdit: false,
            todo: {id: '', title: '', completed: false},
            todos: []
        },
        mounted() {
            this.$http.get('todo').then(response => {
                this.todos = response.body.data;
            });
        },
        methods: {
            addTodo() {
                if (this.todo.title == '') {
                    this.showError = true;
                } else {
                    this.showError = false;
                    if (this.enableEdit) {
                        this.$http.put('todo/' + this.todo.id, this.todo).then(response => {
                            if (response.status == 200) {
                                this.todos[this.todo.todoIndex] = this.todo;
                            }
                        });
                        this.todo = {id: '', title: '', completed: false};
                        this.enableEdit = false;
                    } else {
                        this.$http.post('todo', {title: this.todo.title}).then(response => {
                            if (response.status == 201) {
                                this.todos.push({
                                    id: response.body.todo_id,
                                    title: this.todo.title,
                                    completed: false
                                });
                                this.todo = {id: '', title: '', completed: false};
                            }
                        });
                    }
                }
            },
            checkForEnter(event) {
                if (event.key == "Enter") {
                    this.addTodo();
                }
            },
            toggleTodo(todo, todoIndex) {
                var completedToggle;
                if (todo.completed == true) {
                    completedToggle = false;
                } else {
                    completedToggle = true;
                }
                this.$http.put('todo/' + todo.id, {id: todo.id, title: todo.title, completed: completedToggle}).then(response => {
                    if (response.status == 200) {
                        this.todos[todoIndex].completed = completedToggle;
                    }
                });
            },
            editTodo(todo, todoIndex) {
                this.enableEdit = true;
                this.todo = todo;
                this.todo.todoIndex = todoIndex;
            },
            deleteTodo(todo, todoIndex) {
                if (confirm("Are you sure ?")) {
                    this.$http.delete('todo/' + todo.id).then(response => {
                        if (response.status == 200) {
                            this.todos.splice(todoIndex, 1);
                            this.todo = {id: '', title: '', completed: false};
                        }
                    });
                }
            }
        }
    });
</script>
</body>
</html>
