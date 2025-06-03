import { createRouter, createWebHistory } from 'vue-router';
import Home from './views/Home.vue';
import Chart from './views/Chart.vue';

const routes = [
    { path: '/', name: 'Home', component: Home },
    { path: '/chart', name: 'Chart', component: Chart }
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

export default router