// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";

import { Socket } from "phoenix";
import LiveSocket from "phoenix_live_view";
import "lite-youtube-embed";
import "lite-youtube-embed/src/lite-yt-embed.css";

const hooks = {
  Autofocusing: {
    mounted() {
      this.el.focus();
    }
  },
  Autoselecting: {
    mounted() {
      this.el.select();
    }
  }
};

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks
});
liveSocket.connect();

import Vue from "vue";
import VueEditor from "./editor.vue";

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

document.querySelectorAll(".vue-editor").forEach(node => {
  new Vue({
    el: node,
    render: h => h(VueEditor, { props: { content: node.textContent } })
  });
});
