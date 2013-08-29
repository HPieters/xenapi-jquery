// Generated by CoffeeScript 1.6.2
(function() {
  "use strict";  window.XenAPI = function(username, password, hosturl) {
    var external, internal, _call, _connect, _convertJSON, _getCurrentSession, _getError, _getResult, _getServerVersion, _getSession, _init, _responseHandler, _serializeSession, _serializeUrl, _xmlrpc,
      _this = this;

    _serializeUrl = function(url) {
      if (url.search("http://") === -1 && url.search("https://") === -1) {
        if (url.search("/json") === -1) {
          return "http://" + url + "/json";
        } else {
          return "http://" + url;
        }
      } else {
        if (url.search("/json") === -1) {
          return "" + url + "/json";
        } else {
          return url;
        }
      }
    };
    _serializeSession = function(session) {
      var e;

      try {
        return session.replace(/"/g, "");
      } catch (_error) {
        e = _error;
        return $.error("Unable to replace session string - " + e);
      }
    };
    _connect = function(username, password, hostUrl, callback) {
      return _xmlrpc(hostUrl, "session.login_with_password", [username, password], callback);
    };
    _getResult = function(result, element) {
      var e;

      try {
        return result[0][element];
      } catch (_error) {
        e = _error;
        return $.error("Unable to process the result - " + e);
      }
    };
    _getError = function(error) {
      var e, str, _i, _len;

      str = "Error: ";
      for (_i = 0, _len = error.length; _i < _len; _i++) {
        e = error[_i];
        str += e + " ";
      }
      return str;
    };
    _convertJSON = function(string) {
      var e;

      try {
        return $.parseJSON(string);
      } catch (_error) {
        e = _error;
        return $.error("Failed to parse returning JSON - " + e);
      }
    };
    _responseHandler = function(status, response, list, callback) {
      var error, messageStatus, ret;

      if (status === "success") {
        if (!list === true) {
          messageStatus = _getResult(response, "Status");
          if (messageStatus === "Success") {
            ret = _convertJSON(_getResult(response, "Value"));
            return callback(null, ret);
          } else {
            error = _getError(_getResult(response, "ErrorDescription"));
            return callback(error);
          }
        } else {
          return callback(null, response);
        }
      } else {
        error = "Error: Failed to connect to specified host.";
        return callback(error);
      }
    };
    _xmlrpc = function(url, method, parameters, callback) {
      var list;

      list = false;
      if (parameters === true) {
        parameters = [];
        list = true;
      }
      return $.xmlrpc({
        url: url,
        methodName: method,
        params: parameters,
        success: function(response, status, jqXHR) {
          return _responseHandler(status, response, list, callback);
        },
        error: function(jqXHR, status, error) {
          return _responseHandler(status, error, list, callback);
        }
      });
    };
    _call = function(method, parameters, callback) {
      var main;

      if ((internal.account.username != null) && (internal.account.password != null) && (internal.account.hosturl != null)) {
        main = function(callback) {
          var session;

          if (parameters === true) {
            parameters = [];
          } else {
            if (parameters instanceof Array) {
              parameters = parameters;
            } else {
              parameters = [parameters];
            }
          }
          session = _serializeSession(internal.session);
          parameters.unshift(session);
          return _xmlrpc(internal.account.hosturl, method, parameters, callback);
        };
        if (!parameters === false) {
          if (internal.session != null) {
            return main(callback);
          } else {
            return _connect(internal.account.username, internal.account.password, internal.account.hosturl, function(err, res) {
              if (err) {
                return callback(err);
              } else {
                internal.session = res;
                return main(callback);
              }
            });
          }
        } else {
          return _xmlrpc(internal.account.hosturl, method, true, callback);
        }
      } else {
        return callback("Error: No settings found, make sure you initiate the class first.");
      }
    };
    _getServerVersion = function(callback) {
      var version;

      version = {};
      return _call("pool.get_all_records", true, function(err, result) {
        var parameters, poolref;

        if (err) {
          return callback(err);
        } else {
          poolref = Object.keys(result)[0];
          parameters = result[poolref].master;
          return _call("host.get_API_version_major", parameters, function(err, result) {
            if (err) {
              return callback(err);
            } else {
              version.mayor = result;
              return _call("host.get_API_version_minor", parameters, function(err, result) {
                if (err) {
                  return callback(err);
                } else {
                  version.minor = result;
                  return _call("host.get_software_version", parameters, function(err, result) {
                    if (err) {
                      return callback(err);
                    } else {
                      version.version = result;
                      return callback(null, version);
                    }
                  });
                }
              });
            }
          });
        }
      });
    };
    _getCurrentSession = function() {
      if (internal.session) {
        return internal.session;
      } else {
        return $.error("Unable to retreive session because no session is yet defined.");
      }
    };
    _getSession = function(callback) {
      return _connect(internal.account.username, internal.account.password, internal.account.hosturl, function(err, res) {
        if (err) {
          return callback(err);
        } else {
          internal.session = res;
          return callback(null, res);
        }
      });
    };
    _init = function(callback) {
      var ext;

      ext = external;
      return _call("system.listMethods", false, function(err, res) {
        var e, elem, element, item, key, values, _i, _j, _len, _len1;

        if (err) {
          return callback(err);
        } else {
          try {
            for (_i = 0, _len = res.length; _i < _len; _i++) {
              elem = res[_i];
              for (_j = 0, _len1 = elem.length; _j < _len1; _j++) {
                item = elem[_j];
                values = item.split('.');
                key = values[0];
                element = values[1];
                if (!external[key]) {
                  ext[key] = {};
                }
                ext[key][element] = (function(key, element) {
                  return function(parameters, callback) {
                    var method;

                    if (arguments.length === 1) {
                      if (Object.prototype.toString.call(parameters === "[object Function]")) {
                        callback = parameters;
                        parameters = true;
                      }
                    }
                    method = key + '.' + element;
                    return _call(method, parameters, callback);
                  };
                })(key, element);
              }
            }
            return callback(null, true);
          } catch (_error) {
            e = _error;
            return callback("Error: Failed to fetch api calls - " + e);
          }
        }
      });
    };
    internal = {};
    internal.account = {
      username: username,
      password: password,
      hosturl: _serializeUrl(hosturl)
    };
    external = {};
    external.init = function(callback) {
      return _init(callback);
    };
    external.serverVersion = function(callback) {
      return _getServerVersion(callback);
    };
    external.getSession = function(callback) {
      return _getSession(callback);
    };
    external.currentSession = function() {
      return _getCurrentSession();
    };
    return external;
  };

}).call(this);
