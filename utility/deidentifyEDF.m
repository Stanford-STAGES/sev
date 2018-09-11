%DEIDENTIFYEDF  Deidentify EDF file header data.
%   STATUS = DEIDENTIFYEDF(FILENAME) 
%   STATUS = DEIDENTIFYEDF(FILENAME,[]) 
%
%   STATUS = DEIDENTIFYEDF(FILENAME, DESTINATION_FILENAME)
%
%   STATUS = DEIDENTIFYEDF(FILENAME, DESTINATION_PATHNAME)
%
%   STATUS codes:
%        0  Filename given does not exist
%       -3  Unable to open .edf file
%       -2  File is not a valid .edf or has been corrupted
%        1  Success
%        2  EDF+ file.  File header is deidentified, however file is EDF+ and may have identifiable information in channel annotations
function status = deidentifyEDF(filename, filenameOut)
narginchk(1,2);

if(~exist(filename,'file'))
    status = 0;
    printError(status, filename);
    return;
end

if(nargin==2 && ~isempty(filenameOut))
    if(isdir(filenameOut))
        [~, name, ext] = fileparts(filename);
        filenameOut = fullfile(filenameOut, [name ext]);
    end
    try copyfile(filename,filenameOut)
        
        if(exist(filenameOut,'file'))
            filename = filenameOut;
        else
            status = -1;
            printError(status,filenameOut);            
        end            
    catch me
        status = -1;
        showME(me);
        printError(status,filenameOut);
        return;
    end
end

% At this point we have a valid edf file that exists and needs to be
% deidentified.
status = deidentifyHeader(filename);

end


function printError(status, param)
switch status
    case -3
        fprintf('Unable to open .edf file (%s)\n',param);    
    case -2
        fprintf('File is not a valid .edf or has been corrupted (%s)\n',param);
    case -1
        fprintf('Unable to create output file (%s)\n',param);
    case 0
        fprintf('Filename given does not exist (%s)\n',param);
    case 1
        
    case 2
        fprintf('File header is deidentified, however file is EDF+ and may have identifiable information in channel annotations (%s)\n',param);
    otherwise
        fprintf('Unknown status code: %d\n',status);
end

end

function status = deidentifyHeader(filename)
    
    localString = repmat(uint8(' '),1,80);
    startDay = '01';
    %handle filenames with unicode characters in them
    filename = char(unicode2native(filename,'utf-8'));
    fid = fopen(filename,'r+');  % 'r+'    open (do not create) file for reading and writing
    if(fid<1)
        status = -3;
        printError(status);
    else
        precision = 'uint8';
        frewind(fid);
        HDR.ver = str2double(char(fread(fid,8,precision)'));% 8 ascii : version of this data format (0)
        fseek(fid,0,'cof');
        %HDR.patient = char(fread(fid,80,precision)');% 80 ascii : local patient identification (mind item 3 of the additional EDF+ specs)')
        %HDR.local = char(fread(fid,80,precision)');% 80 ascii : local recording identification (mind item 4 of the additional EDF+ specs)')
        fwrite(fid,localString);  % space out local patient information
        fwrite(fid,localString);  % space out local recording information
        %8 ascii : startdate of recording (dd.mm.yy)
        fwrite(fid,startDay,precision);
        fseek(fid,-2,'cof'); %need to call fseek between read and write operations in matlab
        HDR.startdate = char(fread(fid,8,precision)');% 8 ascii : startdate of recording (dd.mm.yy)') (mind item 2 of the additional EDF+ specs)')
        HDR.starttime = char(fread(fid,8,precision)');% 8 ascii : starttime of recording (hh.mm.ss)')
        HDR.HDR_size_in_bytes = str2double(char(fread(fid,8,precision)'));% 8 ascii : number of bytes in header record
        HDR.reserved = char(fread(fid,44,precision)');% 44 ascii : reserved
        % 'EDF+C' means continuous recording
        % 'EDF+D' means interrupted recording (DISCONTINUOUS)
        % See EDF+ spec at http://www.edfplus.info/specs/edfplus.html
        
        if(HDR.ver ~= 0)
            status = -2; % not in correct format
        else
            try
                if(strncmpi(HDR.reserved,'EDF+',4))
                    status = 2;
                else
                    status = 1;
                end
            catch me
                showME(me);
                status = -3;
            end
            
        end
        fclose(fid);
    end
end