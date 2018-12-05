function sev_pathname = sev_pathsetup()
    
    import plist.*; %struct to xml plist format conversions and such
    import detection.*; %detection algorithms and such
    import filter.*;
    import batch.*;
    
    sev_pathname = fileparts(mfilename('fullpath'));
    
    subPaths = {'auxiliary','utility','classes','figures','widgets','external/widgets'};
    cellfun(@(x)addpath(fullfile(sev_pathname,x)),subPaths);
end