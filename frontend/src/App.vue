<script setup>
import { computed, onMounted, ref } from 'vue'

const tasks = ref([])
const title = ref('')
const loading = ref(false)
const error = ref('')

const remainingCount = computed(() => tasks.value.filter((task) => !task.completed).length)

async function request(path, options = {}) {
  const response = await fetch(path, {
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
    ...options,
  })

  if (!response.ok) {
    const message = await response.text()
    throw new Error(message || `Request failed with ${response.status}`)
  }

  if (response.status === 204) {
    return null
  }

  return response.json()
}

async function loadTasks() {
  loading.value = true
  error.value = ''
  try {
    tasks.value = await request('/api/tasks')
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

async function addTask() {
  const nextTitle = title.value.trim()
  if (!nextTitle) {
    return
  }

  error.value = ''
  try {
    const task = await request('/api/tasks', {
      method: 'POST',
      body: JSON.stringify({ title: nextTitle }),
    })
    tasks.value = [task, ...tasks.value]
    title.value = ''
  } catch (err) {
    error.value = err.message
  }
}

async function toggleTask(task) {
  error.value = ''
  try {
    const updated = await request(`/api/tasks/${task.id}/toggle`, { method: 'PATCH' })
    tasks.value = tasks.value.map((item) => (item.id === updated.id ? updated : item))
  } catch (err) {
    error.value = err.message
  }
}

async function deleteTask(task) {
  error.value = ''
  try {
    await request(`/api/tasks/${task.id}`, { method: 'DELETE' })
    tasks.value = tasks.value.filter((item) => item.id !== task.id)
  } catch (err) {
    error.value = err.message
  }
}

onMounted(loadTasks)
</script>

<template>
  <main class="app-shell">
    <section class="task-panel" aria-labelledby="page-title">
      <div class="panel-header">
        <div>
          <p class="eyebrow">Vue + Java + H2</p>
          <h1 id="page-title">Sample task board</h1>
        </div>
        <span class="counter">{{ remainingCount }} open</span>
      </div>

      <form class="task-form" @submit.prevent="addTask">
        <input
          v-model="title"
          type="text"
          maxlength="120"
          placeholder="Add a task"
          aria-label="Task title"
        />
        <button type="submit">Add</button>
      </form>

      <p v-if="error" class="error">{{ error }}</p>
      <p v-if="loading" class="empty">Loading tasks...</p>

      <ul v-else class="task-list">
        <li v-for="task in tasks" :key="task.id" :class="{ done: task.completed }">
          <label>
            <input type="checkbox" :checked="task.completed" @change="toggleTask(task)" />
            <span>{{ task.title }}</span>
          </label>
          <button class="ghost-button" type="button" @click="deleteTask(task)">Delete</button>
        </li>
      </ul>
    </section>
  </main>
</template>
