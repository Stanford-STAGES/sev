classdef CLASS_method_export < CLASS_method_module
    properties(Constant)
        MODULE = 'export';
    end
    methods
        % sourcePath, exportPath, params, varargin)   
        function this = CLASS_method_export(varargin)
            this = this@CLASS_method_module(varargin{:});
        end
        function didEval = methodFcn(this, sourcePath, exportPath, varargin)
            
            didEval = false;
            if(isdir(sourcePath))
                if(nargin<2 || isempty(this.params))
                    this.params = this.getParamsFromFile();
                end
                
                if(~isfield(this.params,'channelLabel'))
                    this.params.channelLabel = 'all';
                end
                if(isnan(this.params.channelLabel))
                    this.params.channelLabel = 'all';
                end
                
                if(numel(varargin)>0 && ~isempty(varargin{1}))
                    this.params.channelLabel = varargin{1};
                end
                try
                    this.exportFcn(sourcePath, exportPath, varargin{:});
                    didEval = true;
                catch me
                    showME(me);
                    didEval = false;
                end
            end            
        end
    end

    methods(Abstract)
        exportFcn(this)
    end
    
    methods(Static)
        function defaults = getDefaultParams()
            defaults.channelLabel = 'all';
        end
    end
end