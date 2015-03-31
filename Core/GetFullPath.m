function File = GetFullPath(File)
% GetFullPath - Get absolute path of a file or folder [MEX]
% FullName = GetFullPath(Name)
% INPUT:
%   Name: String or cell string, file or folder name with or without relative
%         or absolute path.
%         Unicode characters and UNC paths are supported.
%         Up to 8192 characters are allowed here, but some functions of the
%         operating system may support 260 characters only.
%
% OUTPUT:
%   FullName: String or cell string, file or folder name with absolute path.
%         "\." and "\.." are processed such that FullName is fully qualified.
%         For empty strings the current directory is replied.
%         The created path need not exist.
%
% NOTE: The Mex function calls the Windows-API, therefore it does not run
%   on MacOS and Linux.
%   The magic initial key '\\?\' is inserted on demand to support names
%   exceeding MAX_PATH characters as defined by the operating system.
%
% EXAMPLES:
%   cd(tempdir);                    % Here assumed as C:\Temp
%   GetFullPath('File.Ext')         % ==>  'C:\Temp\File.Ext'
%   GetFullPath('..\File.Ext')      % ==>  'C:\File.Ext'
%   GetFullPath('..\..\File.Ext')   % ==>  'C:\File.Ext'
%   GetFullPath('.\File.Ext')       % ==>  'C:\Temp\File.Ext'
%   GetFullPath('*.txt')            % ==>  'C:\Temp\*.txt'
%   GetFullPath('..')               % ==>  'C:\'
%   GetFullPath('Folder\')          % ==>  'C:\Temp\Folder\'
%   GetFullPath('D:\A\..\B')        % ==>  'D:\B'
%   GetFullPath('\\Server\Folder\Sub\..\File.ext')
%                                   % ==>  '\\Server\Folder\File.ext'
%   GetFullPath({'..', 'new'})      % ==>  {'C:\', 'C:\Temp\new'}
%
% COMPILE: See GetFullPath.c
%   Run the unit-test uTest_GetFullPath after compiling.
%
% Tested: Matlab 6.5, 7.7, 7.8, WinXP, 32bit
% Compiler: LCC 2.4/3.8, OpenWatcom 1.8, BCC 5.5, MSVC 2008
% Author: Jan Simon, Heidelberg, (C) 2010-2011 matlab.THISYEAR(a)nMINUSsimon.de
%
% See also Rel2AbsPath, CD, FULLFILE, FILEPARTS.

% $JRev: R-q V:016 Sum:jDat59+lbOpA Date:27-Apr-2011 10:16:42 $
% $License: BSD (use/copy/change/redistribute on own risk, mention the author) $
% $UnitTest: uTest_GetFullPath $
% $File: Published\GetFullPath\GetFullPath.m $
% History:
% 001: 20-Apr-2010 22:28, Successor of Rel2AbsPath.
% 010: 27-Jul-2008 21:59, Consider leading separator in M-version also.
% 011: 24-Jan-2011 12:11, Cell strings, '~File' under linux.
%      Check of input types in the M-version.
% 015: 31-Mar-2011 10:48, BUGFIX: Accept [] as input as in the Mex version.
%      Thanks to Jiro Doke, who found this bug by running the test function for
%      the M-version.

% Initialize: ==================================================================
% Do the work: =================================================================

% #############################################
% ### USE THE MUCH FASTER MEX ON WINDOWS!!! ###
% #############################################

% Difference between M- and Mex-version:
% - Mex-version cares about the limit MAX_PATH.
% - Mex does not work under MacOS/Unix.
% - M is remarkably slower.
% - Mex calls Windows system function GetFullPath and is therefore much more
%   stable.
% - Mex is much faster.

% Disable this warning for the current Matlab session:
%   warning off JSimon:GetFullPath:NoMex
% If you use this function e.g. under MacOS and Linux, remove this warning
% completely, because it slows down the function by 40%!
%warning('JSimon:GetFullPath:NoMex', ...
%  'GetFullPath: Using slow M instead of fast Mex.');

% To warn once per session enable this and remove the warning above:
%persistent warned
%if isempty(warned)
%   warning('JSimon:GetFullPath:NoMex', ...
%           'GetFullPath: Using slow M instead of fast Mex.');
%    warned = true;
% end

% Handle cell strings:
% NOTE: It is faster to create a function @cell\GetFullPath.m under Linux,
% but under Windows this would shaddow the fast C-Mex.
if isa(File, 'cell')
   for iC = 1:numel(File)
      File{iC} = GetFullPath(File{iC});
   end
   return;
end

if isempty(File)  % Accept empty matrix as input
   if ischar(File) || isnumeric(File)
      File = cd;
      return;
   else
      error(['JSimon:', mfilename, ':BadInputType'], ...
         'Input must be a string or cell string');
   end
end

if ischar(File) == 0  % Non-empty inputs must be strings
   error(['JSimon:', mfilename, ':BadInputType'], ...
      'Input must be a string or cell string');
end

winStyle = strncmpi(computer, 'PC', 2);
if winStyle
   FSep = '\';
   File = strrep(File, '/', FSep);
else  % Linux:
   FSep = '/';
   File = strrep(File, '\', FSep);
   
   if strcmp(File, '~') || strncmp(File, '~/', 2)  % Home directory:
      HomeDir = getenv('HOME');
      if length(HomeDir)
         File(1) = [];
         File    = [HomeDir, File];
      end
   end
end

isUNC   = strncmp(File, '\\', 2);
FileLen = length(File);
if isUNC == 0                       % Not a UNC path
   % Leading file separator means relative to current drive or base folder:
   ThePath = cd;
   if File(1) == FSep
      if strncmp(ThePath, '\\', 2)  % Current directory is a UNC path
         sepInd  = findstr(ThePath, '\');
         ThePath = ThePath(1:sepInd(4));
      else
         ThePath = ThePath(1:3);    % Drive letter only
      end
   end
   
   if FileLen < 2 || File(2) ~= ':'       % Does not start with drive letter
      if ThePath(length(ThePath)) ~= FSep
         if File(1) ~= FSep
            File = [ThePath, FSep, File];
         else  % File starts with separator:
            File = [ThePath, File];
         end
      else     % Current path end with separator, e.g. "C:\":
         if File(1) ~= FSep
            File = [ThePath, File];
         else  % File starts with separator:
            ThePath(length(ThePath)) = [];
            File = [ThePath, File];
         end
      end
      
   elseif winStyle && FileLen == 2 && File(2) == ':'   % "C:" => "C:\"
      % "C:" is the current directory, if "C" is the current disk. But "C:" is
      % converted to "C:\", if "C" is not the current disk:
      if strncmpi(ThePath, File, 2)
         File = ThePath;
      else
         File = [File, FSep];
      end
   end
end

% Care for "\." and "\.." - no efficient algorithm, but the fast Mex is
% recommended at all!
if length(findstr(File, [FSep, '.']))
   hasTrailFSep = (File(length(File)) == FSep);
   if winStyle  % Need "\\" as separator:
      C = dataread('string', File, '%s', 'delimiter', '\\');
   else
      C = dataread('string', File, '%s', 'delimiter', FSep);
   end
   
   % Remove '\.\' directly without side effects:
   C(strcmp(C, '.')) = [];
   
   if isUNC  % Keep the base folder for UNC paths:
      limit = 5;
   else
      limit = 2;
   end
   
   R = 1:length(C);
   for dd = reshape(find(strcmp(C, '..')), 1, [])
      index    = find(R == dd);
      R(index) = [];
      if index > limit
         R(index - 1) = [];
      end
   end
   
   % If you have CStr2String, use the faster:
   %   File = CStr2String(C(R), FSep, hasTrailFSep);
   if winStyle
      File = sprintf('%s\\', C{R});
   else
      File = sprintf('%s/', C{R});
   end
   if ~hasTrailFSep
      File = File(1:length(File) - 1);
   end
   
   if winStyle && length(File) == 2 && File(2) == ':'
      File = [File, FSep];  % "C:" => "C:\"
    end
end

% return;
