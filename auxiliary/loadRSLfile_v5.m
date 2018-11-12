function rslStruct = loadRSLfile_v5(rsl_filename)
%this function takes a Philips Respironics Alice Version 5 formatted event file
%(.rsl) and returns a SEV event struct. 

% Notes:  
% p0000001.xml - shows patient data string
% <patient name="AL_1_060209.edf" first="" birth="19000101" gender="M" type="0" timestamp="1305661694" gest="0">
%   <acqui acq="1" acq_machine="EDF" appli="12" cnf="" start="20090602204711" end="20090603074111" size="104" video="no" machine="edf_import" archived="0" xpap_type="1" lightsoff="20090602225711" lightson="20090603072611"/>
% </patient>

% 273       281               294           366                 390[4]          403[2]      405[2]     407 408       409         430              435                                439[30]         [469]               
% <?>       <import type>     <file type>   <start identifier>  <id?>           <evtStart>  <evt size>     <evtID?>  <long name> <abreviated text>                                   <padding>                                                                    
% J)&J      EDF               autorange     220                 10 18 50 1      +? (43 16)  66 (66 0)    0   3      Hypopnea    Hypo               {0 5/1280, 8 9/2312}/(151520512)   -1                                                                  
% 
% [ 403] - event descriptions here ...
% [1261] - events start here ...

% u0002.rsl
% 10   16   23    0    1    3       [194   87  128    0 ][   0   64    0    0 ]   0 [  59 ] 0  [ 58 ]   0   96     90       0    0
%                        Hypopnea                          Duration in 1/2 seconds   HrBef       HrExt     [O2bef] [O2After] %                        
% Event header records (66 bytes)
% 0 [2]   2 [2]   4 [1]   5 [1]  6 [20]      26 [5]      31 [1]  32 [?]   33+? [??]               
% <type>  <size>  <flag>  <ID>  <longname> <shortname>  <pad>   unkown   <padding>                                                                    
% 43 16     66      0       3           Hypopnea   Hypo_          0               -1 (255)
% 31 16   93 2      0 ?      605 (b file)
% Event records (23 bytes)
% 0 [2]   2 [2]   4 [1]   5 [1]  6 [4]      27 [5]      32 [1]  33 [?]   33+? [??]               
% <type>  <size>  <flag>  <ID>   <start offset> <shortname>  <pad>   unkown   <padding>                                                                    
% 10 16     23      1     16     Hypopnea   Hypo_          0               0
%  9 16    125      0     0  
%c000001.rsl - i think it may be a picture of something.   
% 403: [8  16]    [ 91 0 ~ 91 byte record] [3?] 1 
% i00001.rsl
% 403: 63 16  [146 byte records] = channel voltage and scaling perhaps
%      64 16  [213  7 = 2005 byt records
% + B records appear to be in 66 byte chunks starting at 403
% 5 16 [118 0]  channel configurations
%                 [294]
% a0000001.rsl  - autorange
% b0000001.rsl  - ?  records are 605 bytes long
% c0000001.rsl  - context may be pictures given in two parts (each 60 pixels in length)
% e0000001.rsl  - EDF   event (+B listings ..
% f0000001.rsl  - fail (gives each channel though)
% g0000001.rsl  - graph
% i0000001.rsl  - nonsensical ascii (muxed?)
% l0000001.rsl  - channel configurations  (Type 5)
% o0000001.rsl  - lights on lights off
% n0000001.rsl  - user trend
% t0000001.rsl  - trendata
%                   spind, alpha, rem 
% u0000001.rsl  - <empty>
%                 + B Obstructive Apnea O.A.
%                 + B Mixed Apnea M.A.
%                 + B Periodic resp P.R. 




%assume samping rate of 100;
%rslStruct has the following fields
%  .Epoch = 30 second epoch that the start_sample falls in.
%  Start_time %string time in HH:MM:SS format
%  Duration_sec %duration of the event in seconds
%   start_stop_matrix = [Start_sample, Stop_sample]
%   Stage - empty
%   label - string label of the type of event loaded...
%
%   Author: Hyatt Moore IV, Informaton
%   Date created: 10/6/2018

sample_rate = 100; %100 samples per second

if(nargin<1)
    rsl_filename = '/Users/unknown/data/sleep/a0000001/a0000001.rsl';
end

fclose all;
% clc;


% [path,name,ext] = fileparts(rsl_filename);

fid = fopen(rsl_filename,'r');
fseek(fid,0,'bof');

hdr = fread(fid,7,'uint8')';
fseek(fid,7,'bof');

x=fread(fid,[19,6],'uint8')'; %unknown groupings of 19...

4 16 19 0
y = fread(fid,19,'uint8')'; % slightly different grouping ..
z = fread(fid,2,'uint8')'; % a gap
%[74] holds the number of events stored in this file...
%[89:90;108:109;570:571;636:637;702:703;768:769;834:835] same incremental
%difference between consecutive studies...


fseek(fid,142,'bof');  % [142]
patientData = fread(fid,125,'uint8=>char')';  %filename[142:183] gender [184] birthday (yyyymmdd) [186 193]   unknown '0' or 48 [258]
studyName = strtrim(patientData(1:42));
gender = patientData(43);
birthYear = patientData(45:52);
unk = patientData(53:end);

fseek(fid,267,'bof');

%                                           E  D  F   [283]  [294]                     [366]                                  
%  0 3 16 135 0 0 207 143 37 74 23 41 38 74 69 68 70  0 ...  a u t o r a n g e  ... 0  220  
fread(fid, 240,'uint8')
unknown = fread(fid, 1, 'uint16')'; % 768
unknown2 = fread(fid,4,'uint8');
fseek(fid,273,'bof');

%versionInfo = fread(fid,142,'uint8')';
% [294] file description

[267, 408]; %unknown %another +B file, unknown...
fseek(fid,273,'bof');
k = fread(fid,136,'uint8')'
%file start and stop information
start_sec_from_unix_epoch = fread(fid,1,'uint32');
stop_sec_from_unix_epoch = fread(fid,1,'uint32');
start_datenum = datenum(1970,1,1,0,0,start_sec_from_unix_epoch);

datestr(start_datenum,'HH:MM:SS');

%the next section comes in 66 byte chunks
fseek(fid,409,'bof');
eventID = fread(fid,1,'uint8')'; %20 for LM events
eventLabel = fread(fid,60)';

fseek(fid,469,'bof');fread(fid,[66,14],'uint8')';
%these are the channel labels, etc...

ftell(fid);
fseek(fid,1393,'bof');
fstart = ftell(fid);
%events to hold is

fseek(fid,0,'eof');
fend = ftell(fid);
fseek(fid,fstart,'bof');
numEvents = (fend-fstart)/23;

evtStruct.unknownDate = [];
evtStruct.ID = [];
evtStruct.startSecond =[];
evtStruct.durationInHalfSeconds =[];
evtStruct.type = [];
evtStruct.unknownFinish = [];
evtStruct.startTime = [];
%  Duration_sec
%   Start_sample
%   Stop_sample
%   Epoch
%   Stage
duration_seconds = zeros(numEvents,1);
Start_sample = zeros(numEvents,1);
Stop_sample = zeros(numEvents,1);
Epoch = zeros(numEvents,1);
start_time = cell(numEvents,1);
evtStruct = repmat(evtStruct,numEvents,1);
label = cell(numEvents,1);

% 413 
%  8  1   6 255   9 85 16 15 0 1 37 0  0  0  0  %16 byte boundaries
%  8  85  5 170  10 85 16 15 0 1 37 0  0  0  0
%  9  22  8  20  24 85 16 15 0 1 37 0  0  0  0
%  9 170 10  84  21 85 16 15 0 1 37 0  0  0  0
% 10  87  4  85  12 85 16 15 0 1 37 
%repeat the following for the number of events that we have....
fprintf(1,'Type\tElapsedStart\tDuration\n');
for k=1:numEvents
    fread(fid,1,'uint8'); %get the 10, or \n
    evtStruct(k).unknownDate = fread(fid,1,'uint32'); %get the date?
    evtStruct(k).ID = fread(fid,1,'uint16'); %get the event ID
    evtStruct(k).elapsedHalfSeconds = fread(fid,1,'uint32');  %number of 1/2 seconds elapsed from start
    evtStruct(k).durationInHalfSeconds = fread(fid,1,'uint32'); %duration as 0.5-s chunks
    evtStruct(k).type = fread(fid,1,'uint32'); %LM type?
    evtStruct(k).unknownFinish = fread(fid,1,'uint32'); %unknown
    
    start_datenum = datenum(1970,1,1,0,0,start_sec_from_unix_epoch+evtStruct(k).elapsedHalfSeconds/2);
    start_time{k} = datestr(start_datenum,'HH:MM:SS');

    if(evtStruct(k).ID==20)
        label{k} = 'LM_AASM2007';
    elseif(evtStruct(k).ID==50)
        label{k} = 'LM_maybe';
    else
        label{k} = 'unknown';
    end;
    duration_seconds(k) = evtStruct(k).durationInHalfSeconds*0.5;
    Start_sample(k) = evtStruct(k).elapsedHalfSeconds/2*sample_rate;
    Stop_sample(k) =  Start_sample(k)+duration_seconds(k)*sample_rate;
    Epoch(k) = ceil(Start_sample(k)/30/sample_rate); %1st sample is in epoch 1

    fprintf(1,'%s\t%s\t%0.1f\n',label{k},start_time{k},evtStruct(k).durationInHalfSeconds*0.5);
end


rslStruct.label = label;
rslStruct.duration_seconds = duration_seconds;
rslStruct.start_stop_matrix = [Start_sample,Stop_sample];
rslStruct.epoch = Epoch;
rslStruct.stage = zeros(numEvents,1);
rslStruct.start_time = start_time;
fclose(fid);