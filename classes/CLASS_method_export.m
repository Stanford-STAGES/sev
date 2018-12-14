classdef CLASS_method_export < CLASS_method_module
    events
        ExportExceptionCaught;
    end
    properties(Constant)
        MODULE = 'export';
    end

    methods
        % sourcePath, exportPath, params, varargin)   
        function this = CLASS_method_export(varargin)
            this = this@CLASS_method_module(varargin{:});
        end
        function init(this)
            this.addlistener('ExportExceptionCaught',@this.exportExceptionCaughtCb);
            this.status.exception = false;
            this.status.finished = false;
            this.status.started = false;
        end
        function exportExceptionCaughtCb(this, varargin)
            this.status.exception = true;
            
        end
        function didEval = methodFcn(this, sourcePath, exportPath, varargin)
            this.status.started   = true;
            this.status.finished  = false;
            this.status.exception = false;
            
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
                    this.status.finished = true;
                catch me
                    showME(me);
                    this.notify('ExportExceptionCaught');
                end
            end
            didEval = this.status.finished;
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