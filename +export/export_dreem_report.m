function didExport = export_dreem_report(sourcePath, destPath, params, varargin)

    % initialize default parameters
    addpath('~/git/informaton.dev/tools/dreemClean/');
    defaultParams = dreemCleanReport();

    
    
    % return default parameters if no input arguments are provided.
    if(nargin==0)
        didExport = defaultParams;
    else
        try
            didExport = false;
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
                
                if(~iscell(params.CHANNEL_LABELS) && isnan(params.CHANNEL_LABELS))
                    params.CHANNEL_LABELS = defaultParams.CHANNEL_LABELS;
                end
                
                if(numel(varargin)>0 && ~isempty(varargin{1}))
                    params.CHANNEL_LABELS = varargin{1};
                end
                
                dreemCleanReport(sourcePath,  params);
                didExport = true;
            end
        catch me
            showME(me);
        end
    end
end