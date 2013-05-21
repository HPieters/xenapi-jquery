#
# jQuery XenServer API
#
# Copyright (C) 2013 - Harrie Pieters
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation; version 2.1 only.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.

"use strict"

window.XenAPI = (username, password, hosturl) ->

	# Internal Functions

 	# Serialize user given url to xenserver compatible url.
 	# @param {String} url
 	# @return {String} url
	_serializeUrl = (url) =>
		if url.search("http://") is -1 and url.search("https://") is -1
			if url.search("/json") is -1
				"http://#{url}/json"
			else
				"http://#{url}"
		else
			if url.search("/json") is -1
				"#{url}/json"
			else
				url

 	# Serialize callback session string to xenserver compatible session.
 	# @param {String} session
 	# @return {String} session
	_serializeSession = (session) =>
		try
			session.replace /"/g, ""
		catch e
			$.error "Unable to replace session string - #{e}"



	# Serialize callback session string to xenserver compatible session.
 	# @param {String} username
 	# @param {String} password
 	# @param {String} session
 	# @param {Function} callback
 	# @return {Function}
	_connect = (username, password, hostUrl, callback) =>
		_xmlrpc(hostUrl, "session.login_with_password", [username, password], callback)

	# Given a result from XenServer return raw or parsed result.
 	# @param {Object} result
 	# @param {String} element
 	# @return {Object}
	_getResult = (result, element) =>
		try
			result[0][element]
		catch e
			$.error "Unable to process the result - #{e}"

	# Given a error from XenServer return raw or parsed error.
 	# @param {Object} error
 	# @param {String} element
 	# @return {Object / String}
	_getError = (error) =>
		str = "Error: "
		str += e + " " for e in error
		str

	# Given a string convert it into a JSON
 	# @param {String} string
 	# @return {Object}
	_convertJSON = (string) =>
		try
			$.parseJSON string
		catch e
			$.error "Failed to parse returning JSON - #{e}"

	# Given a RPC response handle result and return response.
 	# @param {String} status
 	# @param {Object} response
  	# @param {Boolean} list
  	# @param {Function} callback
 	# @return {Function}
	_responseHandler = (status, response, list, callback) =>
		if status is "success"
			if not list is true
				messageStatus = _getResult(response,"Status")
				if messageStatus is "Success"
					ret = _convertJSON _getResult(response,"Value")
					callback(null,ret)
				else
					error = _getError _getResult(response,"ErrorDescription")
					callback error
			else
				callback(null,response)
		else
			error = "Error: Failed to connect to specified host."
			callback error

	# Make the actual call to the XML RPC server of XenServer.
 	# @param {String} url
 	# @param {String} method
  	# @param {String} parameters
  	# @param {Function} callback
 	# @return {Function}
	_xmlrpc = (url, method, parameters, callback) =>
		list = false
		if parameters is true
			parameters = []
			list = true
		$.xmlrpc
			url: url
			methodName: method
			params: parameters
			success: (response, status, jqXHR) ->
					_responseHandler(status, response, list, callback)
			error: (jqXHR, status, error) ->
					_responseHandler(status, error, list, callback)

	# Process a call made by the user.
 	# @param {String} method
  	# @param {String} parameters
  	# @param {Function} callback
 	# @return {Function}
	_call = (method, parameters, callback) ->
		if internal.account.username? and internal.account.password? and internal.account.hosturl?
			#Main is called when the internal.session is available.
			main = (callback) ->
				if parameters is true
					parameters = []
				else
					parameters = [parameters]
				session = _serializeSession internal.session
				parameters.unshift session
				_xmlrpc(internal.account.hosturl, method, parameters, callback)

			#Check for call type (init call is different) and get session token if there is none
			if not parameters is false
				if internal.session?
					main callback
				else
					_connect(internal.account.username, internal.account.password, internal.account.hosturl, (err, res) ->
						if err
							callback err
						else
							internal.session = res
							main callback
					)
			else
				_xmlrpc(internal.account.hosturl, method, true, callback)
		else
			callback "Error: No settings found, make sure you initiate the class first."

	# Get server version
  	# @param {Function} callback
 	# @return {Function}
	_getServerVersion = (callback) ->
		version = {}
		_call("pool.get_all_records", true, (err, result) ->
			if err
				callback err
			else
				poolref 	= Object.keys(result)[0]
				parameters 	= result[poolref].master

				_call("host.get_API_version_major", parameters, (err, result) ->
					if err
						callback err
					else
						version.mayor = result
						_call("host.get_API_version_minor", parameters, (err, result) ->
							if err
								callback err
							else
								version.minor = result;
								_call("host.get_software_version", parameters, (err, result) ->
									if err
										callback err
									else
										version.version = result
										callback(null,version)
								)
						)
				)
		)


	# Dynamically fetch all methods the XenServer has available and expose them to the user.
  	# @param {Function} callback
 	# @return {Function}
	_init = (callback) ->
		ext = external
		_call("system.listMethods", false, (err, res) ->
			if err
				callback err
			else
				try
					for elem in res
						for item in elem
							values 	= item.split('.');
							key 	= values[0]
							element = values[1]

							if not external[key]
								ext[key] = {}
							ext[key][element] = do (key,element) ->
								(parameters, callback) ->
									if arguments.length is 1
										if Object.prototype.toString.call parameters is "[object Function]"
											callback = parameters;
											parameters = true
									method = key+'.'+element
									_call(method, parameters, callback)
					callback(null,true)
				catch e
					callback "Error: Failed to fetch api calls - #{e}"
		)

	# Internal variables
	internal 			= {}
	internal.account 	=
		username: username
		password: password
		hosturl: _serializeUrl hosturl

	# External variables
	external = {}

	# External abstraction of internal _init function
  	# @param {Function} callback
 	# @return {Function}
	external.init = (callback) ->
		_init callback

	# External abstraction of internal _getServerVersion function
  	# @param {Function} callback
 	# @return {Function}
	external.serverVersion = (callback) ->
		_getServerVersion callback

	# Expose external as methods
	external