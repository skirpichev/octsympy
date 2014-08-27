%% Copyright (C) 2014 Colin B. Macdonald
%%
%% This file is part of OctSymPy.
%%
%% OctSymPy is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published
%% by the Free Software Foundation; either version 3 of the License,
%% or (at your option) any later version.
%%
%% This software is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty
%% of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
%% the GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public
%% License along with this software; see the file COPYING.
%% If not, see <http://www.gnu.org/licenses/>.

%% -*- texinfo -*-
%% @deftypefn {Function File} {@var{r} =} sympref ()
%% Preferences for the OctSymPy symbolic computing package.
%%
%% Python executable path/command:
%% @example
%% sympref python '/usr/bin/python'
%% sympref python 'C:\Python\python.exe'
%% sympref python 'N:\myprogs\py.exe'
%% @end example
%% Default is an empty string; in which case OctSymPy just runs
%% @code{python} and assumes the path is set appropriately.
%%
%% Display of syms:
%% @example
%% sympref display flat
%% sympref display ascii
%% sympref display unicode
%% @end example
%% By default OctSymPy uses a unicode pretty printer to display
%% symbolic expressions.  If that doesn't work (e.g., if you
%% see @code{?} characters) then try the @code{ascii} option.
%%
%% Communication mechanism:
%% @example
%% sympref ipc default    % default, autodetected
%% sympref ipc system     % slower
%% sympref ipc systmpfile % debugging!
%% sympref ipc sysoneline % debugging!
%% w = sympref('ipc')     % query the ipc mechanism
%% @end example
%% The default will typically be the @code{popen2} mechanism which
%% uses a pipe to communicate with Python and should be fairly fast.
%% There are other options which are mostly based on calls using the
%% @code{'system()'} command.  These are slower as a new Python
%% process is started for each operation (and many commands use more
%% than one operation).
%% Other options for @code{sympref ipc} include:
%% @itemize
%% @item popen2, force popen2 choice (e.g., on Matlab were it would
%% not be the default).
%% @item system, construct a large multi-line string of the command
%% and pass directly to the python interpreter with the
%% @code{system()} command.  Warning: currently broken on Windows.
%% @item systmpfile, output the python commands to a
%% @code{temp_sym_python_cmd.py} file and then call that [for
%% debugging, may not be supported long-term].
%% @item sysoneline, put the python commands all on one line and
%% pass to "python -c" using a call to @code{system()}.  [for
%% debugging, may not be supported long-term].
%% @end itemize
%%
%% Reset: reset the SymPy communication mechanism.  This can be
%% useful after an error occurs where the connection with Python
%% becomes confused.
%% @example
%% sympref reset
%% @end example
%%
%% Snippets: when displaying a sym object, we show the first
%% few characters of the SymPy representation.
%% @example
%% sympref snippet 1|0   % or true/false, on/off
%% @end example
%%
%% Report the version number:
%% @example
%% sympref version
%% @end example
%%
%% @seealso{sym, syms}
%% @end deftypefn

function varargout = sympref(cmd, arg)

  persistent settings

  if (isempty(settings))
    settings = 42;
    sympref('defaults')
  end

  if (nargin == 0)
    varargout{1} = settings;
    return
  end


  switch lower(cmd)
    case 'defaults'
      settings = [];
      settings.ipc = 'default';
      settings.display = 'unicode';
      settings.snippet = true;
      settings.whichpython = '';

    case 'version'
      assert (nargin == 1)
      varargout{1} = '0.0.5';

    case 'display'
      if (nargin == 1)
        varargout{1} = settings.display;
      else
        arg = lower(arg);
        assert(strcmp(arg, 'flat') || strcmp(arg, 'ascii') || ...
               strcmp(arg, 'unicode'))
        settings.display = arg;
      end

    case 'snippet'
      if (nargin == 1)
        varargout{1} = settings.snippet;
      else
        settings.snippet = tf_from_input(arg);
      end

    case 'python'
      if (nargin == 1)
        varargout{1} = settings.whichpython;
      elseif (isempty(arg) || strcmp(arg,'[]'))
        settings.whichpython = '';
        sympref('reset')
      else
        settings.whichpython = arg;
        sympref('reset')
      end

    case 'ipc'
      if (nargin == 1)
        varargout{1} = settings.ipc;
      else
        sympref('reset')
        settings.ipc = arg;
        switch arg
          case 'default'
            disp('Choosing the default [autodetect] octsympy communication mechanism')
          case 'system'
            disp('Forcing the system() octsympy communication mechanism')
          case 'popen2'
            disp('Forcing the popen2() octsympy communication mechanism')
          case 'systmpfile'
            disp('Forcing systmpfile ipc: warning: this is for debugging')
          case 'sysoneline'
            disp('Forcing systmpfile ipc: warning: this is for debugging')
            warning('the systmpfile ipc mechanism is under developement, many tests fail');
          otherwise
          warning(['Unknown/unsupported IPC mechanism: hope you know what you''re doing'])
        end
      end

    case 'reset'
      disp('Resetting the octsympy communication mechanism');
      r = python_ipc_driver('reset', []);

      if (nargout == 0)
        if (~r)
          disp('Problem resetting');
        end
      else
        varargout{1} = r;
      end

    otherwise
      error ('invalid input')
  end
end


function r = tf_from_input(s)

  if (~ischar(s))
    r = logical(s);
  elseif (strcmpi(s, 'true'))
    r = true;
  elseif (strcmpi(s, 'false'))
    r = false;
  elseif (strcmpi(s, 'on'))
    r = true;
  elseif (strcmpi(s, 'off'))
    r = false;
  elseif (strcmpi(s, '[]'))
    r = false;
  else
    r = str2double(s);
    assert(~isnan(r), 'invalid expression to convert to bool')
    r = logical(r);
  end
end


%!test
%! sympref('defaults')
%! assert(strcmp(sympref('ipc'), 'default'))

%!test
%! fprintf('\n');
%! syms x
%! r = sympref('reset')
%! pause(1);
%! syms x
%! pause(2);
%! fprintf('\n');
%! assert(r)
