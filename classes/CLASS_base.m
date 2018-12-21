classdef CLASS_base < handle
    properties(SetAccess=protected)
        logHandle = [];
    end
    methods
        
        function logStatus(this, fmtStmt, varargin)
            msg = sprintf(fmtStmt, varargin{:});
            if(isempty(this.logHandle))
                fprintf(1,'%s\n',msg);
            elseif(ishandle(this.logHandle))
                set(this.logHandle,'string',msg);
            else
                fprintf(1,'%s\n',msg);
            end
            
        end
    end
end