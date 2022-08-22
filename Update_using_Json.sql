
create proc [crc].[Update_using_Json] @json nvarchar(max), @schema_name varchar(100), @table_name varchar(300),  @column_n varchar(500), @value varchar(500)
as
	begin
		DECLARE @key VARCHAR(MAX), @val varchar(max), @type int, @isFirstRow int = 1,
		@sql NVARCHAR(MAX), @param nvarchar(300) = N'@val nvarchar(300)',
		@ErrorMessage nvarchar(4000),@ErrorSeverity int,@ErrorState int;

		begin try 
			if (trim(@column_n) is null or @column_n = '')
				throw 50010, 'The column hasn''t been provided', 1
			else if(trim(@schema_name) is null or @schema_name = '')
				throw 50020, 'The schema name has not been provided', 1
			else if(trim(@table_name) is null or @table_name = '')
				throw 50030, 'The table name hasn''t been provided',1
			else
set @sql= 'Update ' + quotename(trim(@schema_name)) + '.' + quotename(trim(@table_name)) + ' SET'

declare db_cursor cursor local for
	select * from openjson(@json)
		open db_cursor
			fetch next from db_cursor into @key, @val, @type

				while @@fetch_status = 0
					begin
						if @isFirstRow = 0
							set @sql = @sql + ','

							if (@type = 1)
								begin
									set @sql = @sql + ' [' + @key + '] = ''' + trim(@val) + ''''
								end

							if(@type =2)
								begin
									set @sql = @sql + ' [' + @key + '] = ' + trim(@val)
								end

							set @isFirstRow = 0

							fetch next from db_cursor into @key, @val, @type
					end

			set @isFirstRow = 1
			close db_cursor
			deallocate db_cursor
			set @sql = @sql + ' where ' + trim(@column_n) + ' = trim(@val)' 
		
			exec sp_executesql @sql, @param, @val=@value
				end try
			begin catch
			  SELECT 
					@ErrorMessage = ERROR_MESSAGE(), 
					@ErrorSeverity = ERROR_SEVERITY(), 
					@ErrorState = ERROR_STATE();

		   RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)

		end catch
			
end