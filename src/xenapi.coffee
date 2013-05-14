#
# jQuery XenServer API
# 
# Copyright (C) 2013 - Harrie Pieters
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation; version 2.1 only. 
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#

"use strict"

class window.xsapi

	#Public
	constructor : (username, password, hosturl) ->
			@username = username
			@password = password
			@hosturl = _serializeUrl(hosturl)

	#Private
	_connect = (username, password, hostUrl, callback) ->
		_xmlrpc(hostUrl, "session.login_with_password", [username, password], callback)

	_getResult = (result, element) =>
		result[0][element]

	_getReferenceResult = (result, reference, element) =>
		result[reference][element]

	_serializeSession = (session) =>
		session.replace /"/g, ""

	_serializeUrl = (url) =>
		"http://#{url}/json"

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
				ret = _getResult(response,"Value")
				callback(null,ret)
			else
				error = _serializeError(_getResult(response,"ErrorDescription"))
				callback error	
		else
			error = "Error: Failed to connect to specified host."
			callback error		

	_xmlrpc = (url, method, params = "[]",callback) ->	
		$.xmlrpc
			url: url
			methodName: method
			params: params
			success: (response, status, jqXHR) ->
					_responseHandler(status, response, callback)
			error: (jqXHR, status, error) -> 
					_responseHandler(status, error, callback)

	#Public
	getServerCall : (method, params, callback) ->
		if @username? and @password? and @hosturl?
			if arguments.length is 2
    			if Object.prototype.toString.call params is "[object Function]"
      				callback = params; 
      				params = false
    
			local = this
			hosturl = @hosturl
			main = (callback) ->
				if params is false
					params = []
				else
					params = [params]
				session = _serializeSession local.session
				params.unshift session
				_xmlrpc(hosturl, method, params, callback)

			if @session?
				main callback
			else 
				_connect(@username, @password, hosturl, (err, res) ->
					if err
						callback err
					else 
						local.session = res
						main callback
				)

			
		else
			callback "Error: No settings found, make sure you initiate the class first."
		
	getServerVersion : (callback) ->
		if @username? and @password? and @hosturl?
			local = this
			local.getServerCall("pool.get_all_records", (err, result) ->
				if err
					callback err
				else
					#Assumption alert... for a second imagen we get valid json all the time
					result 	= _convertJSON result
					poolref = Object.keys(result)[0]
					params 	= _getReferenceResult(result, poolref, 'master')
					local.getServerCall("host.get_API_version_major", params, callback)
			)
		else
			callback "Error: No settings found, make sure you initiate the class first."