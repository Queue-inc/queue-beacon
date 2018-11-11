/* globals alert */
const queueBeacon = {
  show () {
    alert('Module queueBeacon is created sucessfully ');
  }
};

const meta = {
  queueBeacon: [{
    lowerCamelCaseName: 'show',
    args: []
  }]
};

function init (weex) {
  weex.registerModule('queueBeacon', queueBeacon, meta);
}

export default {
  init: init
};
