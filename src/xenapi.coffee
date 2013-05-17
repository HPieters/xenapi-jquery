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

	#Create a new Private object
	internal = {}

	# Create a url that works
	# TODO: check for http & json don't append if they are already added by the user
	internal._serializeUrl = (url) =>
		"http://#{url}/json"

	#Internal
	internal.username = username
	internal.password = password
	internal.hosturl  = internal._serializeUrl hosturl

	#Array of all possible function within XenAPI
	calls =
		VM 	 	: ["get_boot_record", "get_all"]
		pool 	: ["get_all_records"]
		host 	: ["get_API_version_major"]
		session : ["login_with_password"]

	_connect = (username, password, hostUrl, callback) =>
		_xmlrpc(hostUrl, "session.login_with_password", [username, password], callback)

	_getResult = (result, element) =>
		result[0][element]

	_serializeSession = (session) =>
		session.replace /"/g, ""

	_serializeError = (error) =>
		str = "Error: "
		str += e + " " for e in error
		str

	_convertJSON = (string) =>
		try
			$.parseJSON string
		catch e
			$.error "Error: Failed to parse returning JSON"

	_responseHandler = (status, response, callback) =>
		if status is "success"
			messageStatus = _getResult(response,"Status")
			if messageStatus is "Success"
				ret = _convertJSON _getResult(response,"Value")
				callback(null,ret)
			else
				error = _serializeError(_getResult(response,"ErrorDescription"))
				callback error
		else
			error = "Error: Failed to connect to specified host."
			callback error

	_xmlrpc = (url, method, parameters = "[]",callback) =>
		$.xmlrpc
			url: url
			methodName: method
			params: parameters
			success: (response, status, jqXHR) ->
					_responseHandler(status, response, callback)
			error: (jqXHR, status, error) ->
					_responseHandler(status, error, callback)

	_call = (method, parameters, callback) ->
		if internal.username? and internal.password? and internal.hosturl?
			main = (callback) ->
				if parameters is false
					parameters = []
				else
					parameters = [parameters]
				session = _serializeSession internal.session
				parameters.unshift session
				_xmlrpc(internal.hosturl, method, parameters, callback)

			if internal.session?
				main callback
			else
				_connect(internal.username, internal.password, internal.hosturl, (err, res) ->
					if err
						callback err
					else
						internal.session = res
						main callback
				)
		else
			callback "Error: No settings found, make sure you initiate the class first."

	#Public
	external = {}

	#Dynamic
	for key in Object.keys(calls)
		external[key] = {}
		for element in calls[key]
			external[key][element] = do (key, element) ->
				(parameters, callback) ->
					if arguments.length is 1
						if Object.prototype.toString.call parameters is "[object Function]"
							callback = parameters;
							parameters = false
					method = key+"."+element
					_call(method, parameters, callback)

	#Return
	external