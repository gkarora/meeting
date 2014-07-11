import sys
import httplib
import BaseHTTPServer
import socket
import urlparse
import shutil
import os

def run(handler_class, port):
  server_address = ('', port)
  httpd = BaseHTTPServer.HTTPServer(server_address, handler_class)
  httpd.serve_forever()

class Handler (BaseHTTPServer.BaseHTTPRequestHandler):
  server_version = 'meeting/0.1'
  
  def loadFile(self, fileName):
      try:
        f=open(fileName)
      except:
        try:      
          fileName="/usr/service/pub/"+fileName   
          f=open(fileName)
        except IOError as err:
          if err.errno != errno.ENOENT:
            traceback.print_exc()
            self.web_error(httplib.INTERNAL_SERVER_ERROR, "Unexpected exception")
          else:
            self.web_error(httplib.NOT_FOUND)
          
      contents=f.readlines()
      f.close()
      self.loadFile2(contents, fileName)
 
  def loadFile2 (self, contents, pathelem):
    self.send_response(httplib.OK)
    if "style.css" in pathelem:
      self.send_header("content-type", "text/css")
    else:    
      self.send_header("content-type", "text/html")
    self.send_header("content-length", os.path.getsize(pathelem))
    self.end_headers()
    self.wfile.writelines(contents)

  def do_GET(self):
    path_elements=self.path.split('/')[1:]

    if path_elements[0]=='':
      self.send_response(httplib.FOUND)
      self.send_header("Location", "/selectTime.html")
      self.end_headers()
    else:   
      self.loadFile(path_elements[0])

if __name__ == '__main__' :
  port = int(sys.argv[1])
  run(Handler, port)
