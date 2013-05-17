## XenAPI Javascript

A Xen API XMLRPC JavaScript Client Library for working with XenServers & XCP.

### Usage

A quick example how to use the library:

`var client = new XenAPI(username,password,hostUrl);
 client.VM.get_all(function(error, result) {
    var all_vm = result;
 })
`

For a more elaborate example see the test/ folder.

### Under development

This library is currently under active development and is still incomplete.