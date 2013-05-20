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
#

"use strict"

window.XenAPI = (username, password, hosturl) ->

	# Create a new Private object
	internal = {}

	# Create a url that works
	_serializeUrl = (url) =>
		if url.indexOf("http://") is -1 and url.indexOf("https://") is -1
			"http://#{url}/json"
		else
			"#{url}/json"

	# Internal
	internal.account =
		username: username
		password: password
		hosturl: _serializeUrl hosturl
	internal.apiversion =
		mayor: 0,
		minor: 0

	# Private
	_connect = (username, password, hostUrl, callback) =>
		_xmlrpc(hostUrl, "session.login_with_password", [username, password], callback)

	_getResult = (result, element) =>
		result[0][element]

	_serializeSession = (session) =>
		session.replace /"/g, ""

	_convertJSON = (string) =>
		try
			$.parseJSON string
		catch e
			$.error "Failed to parse returning JSON - #{e}"

	_responseHandler = (status, response, list, callback) =>
		if status is "success"
			if list is not true
				messageStatus = _getResult(response,"Status")
				if messageStatus is "Success"
					ret = _convertJSON _getResult(response,"Value")
					callback(null,ret)
				else
					error = _getResult(response,"ErrorDescription")
					callback error
			else
				callback(null,response)
		else
			error = "Error: Failed to connect to specified host."
			callback error

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

	_call = (method, parameters, callback) ->
		if internal.account.username? and internal.account.password? and internal.account.hosturl?
			main = (callback) ->
				if parameters is true
					parameters = []
				else
					parameters = [parameters]
				session = _serializeSession internal.session
				parameters.unshift session
				_xmlrpc(internal.account.hosturl, method, parameters, callback)

			if parameters is false
				_xmlrpc(internal.account.hosturl, method, true, callback)
			else
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
			callback "Error: No settings found, make sure you initiate the class first."

	_getServerVersion = (callback) ->
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
						internal.apiversion.mayor = result
						_call("host.get_API_version_minor", parameters, (err, result) ->
							if err
								callback err
							else
								internal.apiversion.minor = result;
								_call("host.get_software_version", parameters, (err, result) ->
									if err
										callback err
									else
										internal.version = result
										callback(null,internal)
								)
						)
				)
		)

	# Public
	external = {}

	# Static
	external.init = (callback) ->
		_init (err, res) ->
			if err
				callback err
			else
				_getServerVersion (err, res) ->
					if err
						callback err
					else
						callback(null,internal)

	# Dynamic
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
					console.log ext
					callback(null,true)
				catch e
					callback "Error: Failed to fetch api calls - #{e}"
		)

	#Return
	external