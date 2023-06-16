// Karma configuration file for singleRun mode
module.exports = function (config) {
  config.set({
    basePath: "",
    plugins: [],
    client: {
      jasmine: {},
      clearContext: false,
    },
    jasmineHtmlReporter: {
      suppressAll: true,
    },
    coverageReporter: {
      dir: require("path").join(__dirname, "./coverage/app"),
      subdir: ".",
      reporters: [{ type: "html" }, { type: "text-summary" }],
    },
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: false,
    singleRun: true,
    restartOnFileChange: false,
  });
};
