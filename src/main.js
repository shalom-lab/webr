import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import { WebR, Console } from 'webr';
import store from './store'
import router from './router'
import VueFilesPreview from 'vue-files-preview'
import 'vue-files-preview/lib/style.css'


const app = createApp(App);
app.use(store)
app.use(router)
app.use(VueFilesPreview)
app.provide('webR', new WebR())
app.mount('#app');
