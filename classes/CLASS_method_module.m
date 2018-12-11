classdef CLASS_method_module < handle    
    properties(Constant, Abstract)
        MODULE;
    end
    properties(SetAccess=protected)
        params;
    end
    methods
        function this = CLASS_method_module(arg1, arg2, params,varargin)
            if(nargin==0)
                this.params = this.getDefaultParams();
            else
                if(nargin<3 || isempty(params))
                    this.params = this.getParamsFromFile();
                else
                    this.params = params;
                end
                if(nargin<2)
                    arg2 = [];
                end                
                this.methodFcn(arg1, arg2, varargin{:});
            end
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

    end
    methods(Abstract)
        methodFcn(this)
    end
    
    methods(Static, Abstract)
        defaults = getDefaultParams();
    end
    methods(Static)
        function pfile = getpfile()
            pfile =  strcat(mfilename('fullpath'),'.plist');
        end
    end
end