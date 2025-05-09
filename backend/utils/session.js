// utils/session.js

let session = {
  username: null,
  module: null
};

module.exports = {
  setSession: (username, module = null) => {
    session.username = username;
    session.module = module;
  },
  getSession: () => session
};

