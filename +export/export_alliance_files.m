function params = export_alliance_files(sourcePath, destPath, params, varargin)
    if(nargin == 0)        
        x = INFExportAllianceTripleScore([mfilename('fullpath'),'.plist']);
        params = x.params;
    else
        try
            if(isdir(sourcePath))
                if(nargin<2 || isempty(params))
                    
                    pfile =  strcat(mfilename('fullpath'),'.plist');
                    
                    if(exist(pfile,'file'))
                        %load it
                        params = plist.loadXMLPlist(pfile);
                    else
                        %make it and save it for the future
                        params = defaultParams;
                        plist.saveXMLPlist(pfile,params);
                    end
                end
                
                x = INFExportAllianceTripleScore(sourcePath, destPath, params, [], varargin{:});
                params = isa(x,'INFExportAllianceTripleScore') && x.status.finished;
            end
        catch me
            showME(me);
            params = false;
        end
    end
end