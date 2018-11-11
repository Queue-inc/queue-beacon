import Vue from 'vue';

import weex from 'weex-vue-render';

import QueueBeacon from '../src/index';

weex.init(Vue);

weex.install(QueueBeacon)

const App = require('./index.vue');
App.el = '#root';
new Vue(App);
