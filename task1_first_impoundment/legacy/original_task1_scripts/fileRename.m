% fileRename - Rename a file name
% 
% Call the functions as shown below
% 
% fileRename(OldFileName, NewFileName)
% 
% fileRename is a function that takes 2 inputs
% 
% Inputs Types
% ------------
% OldFileName - String
% NewFileName - String
% 
% If your file is in your Current Working Directory
% -------------------------------------------------
% 1. OldFileName - is the old file name with its extension
% 2. NewFileName - is the new file name with its extension
% 
% If your file is not in your Current Working Directory
% -----------------------------------------------------
% 1. OldFileName - is the old file name path with its extension
% 2. NewFileName - is the new file name path with its extension
%  
% Author : Karim Mansour
% E-mail : karim.mansour.eng@gmail.com
% Created: March 27, 2010

function fileRename(OldFileName, NewFileName)

if strcmp(OldFileName,NewFileName)
    error('Can not rename file with its EXACT original name');
end

movefile(OldFileName, NewFileName);