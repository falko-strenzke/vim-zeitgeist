"zeitgeist.vim - a Zeitgeist logger for Vim
"Author : Jonathan Lambrechts <jonathanlambrechts@gmail.com>
"         Falko Strenzke 2022
"Installation : drop this file in a vim plugin folder ($HOME/.vim/plugin, ...) or better install it with a plugin-manager. Vim should be compiled with python enabled.
" License: Feel free to copy, modify without any restriction. Comes without any warranty.

function! ZeitgeistLog(filename, vim_use_id)
python3 << endpython
use_id = vim.eval("a:vim_use_id")
filename = vim.eval("a:filename")
precond = os.getuid() != 0 and os.getenv('DBUS_SESSION_BUS_ADDRESS') != None
if got_zeitgeist and precond and filename:
  use = {
    "read" : Interpretation.ACCESS_EVENT,
    "new" : Interpretation.CREATE_EVENT,
    "write" : Interpretation.MODIFY_EVENT} [use_id]

  uri = "uri-unknown"
  mimetype = "mimetype-unknown"
  try:
    pass
    uri="file://" + filename
    mimetype = mimetypes.guess_type(filename)[0]
  except:
    pass
  else:
    subject = Subject.new_for_values(
      uri=str(uri),
      text=str(uri.rpartition("/")[2]),
      interpretation=str(Interpretation.DOCUMENT),
      manifestation=str(Manifestation.FILE_DATA_OBJECT),
      origin=str(uri.rpartition("/")[0]),
      mimetype=str(mimetype)
    )
    event = Event.new_for_values(
      timestamp=int(time.time()*1000),
      interpretation=str(use),
      manifestation=str(Manifestation.USER_ACTIVITY),
      actor="application://vim",
      subjects=[subject,]
    )
    zeitgeistclient.insert_event(event)
endpython
endfunction

python3 << endpython
import os
import time
import dbus
import vim
import mimetypes
try:
  #import gio
  #import gi
  from zeitgeist.client import ZeitgeistClient
  from zeitgeist.datamodel import Subject, Event, Interpretation, Manifestation
  zeitgeistclient = ZeitgeistClient()
  got_zeitgeist = True
except (RuntimeError, ImportError, dbus.exceptions.DBusException):
  got_zeitgeist = False
endpython
augroup zeitgeist
au!
au BufRead * call ZeitgeistLog (expand("%:p"), "read")
au BufNewFile * call ZeitgeistLog (expand("%:p"), "new")
au BufWrite * call ZeitgeistLog (expand("%:p"), "write")
augroup END

" vim: sw=2
