import { createRouter, createWebHistory } from 'vue-router';
import Home from './views/Home.vue';
import Chart from './views/Chart.vue';
import Setting from './views/Setting.vue';

const routes = [
    { path: '/', name: 'Home', component: Home },
    { path: '/chart', name: 'Chart', component: Chart },
    { path: '/setting', name: 'Setting', component: Setting }
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

export default router