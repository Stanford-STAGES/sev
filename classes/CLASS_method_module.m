classdef CLASS_method_module < CLASS_base
    properties(Constant, Abstract)
        MODULE;
    end
    properties(SetAccess=protected)
        params;
        plistFilename;
        status;
    end
    methods
        function this = CLASS_method_module(arg1, arg2, params,varargin)
            if(nargin==0)
                this.params = this.getDefaultParams();
            elseif(nargin==1 && ischar(arg1))
                this.setpfile(arg1);
            else
                
                if(nargin<3 || isempty(params))
                    this.params = this.getParamsFromFile();
                else
                    this.params = params;
                end
                if(nargin<2)
                    arg2 = [];
                end 
                this.init();
                this.methodFcn(arg1, arg2, varargin{:});
            end
        end
        function init(this)
        end
        
        % this does not work - taken from single method functions that were
        % in the same path as the .plist files being retrieved.; no longer
        % the case here.
        function params = getParamsFromFile(this)
            pfile = this.getpfile();
            if(exist(pfile,'file'))
                %load it
                params = plist.loadXMLPlist(pfile);
            else
                %make it and save it for the future
                params = this.getDefaultParams();
                plist.saveXMLPlist(pfile,params);
            end
        end
        
        
        function setpfile(this, fileName)
            this.plistFilename = fileName;
            this.params = this.getParamsFromFile();
        end
        
        function pfile = getpfile(this)
            pfile =  this.plistFilename;
        end


    end
    methods(Abstract)
        methodFcn(this)
    end
    
    methods(Static, Abstract)
        defaults = getDefaultParams();
    end
end