USE Bascula
GO

CREATE PROC ProcDeleteProveedor
@CodProv INT,
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodProv IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Debe proporcionar el código del proveedor.';
			RETURN;
		END
		
		BEGIN TRANSACTION;
		
		DECLARE @exist_Prov BIT;
        SET @exist_Prov = (SELECT EstadoProv 
							 FROM Proveedor WITH (UPDLOCK, ROWLOCK)
							 WHERE CodProv = @CodProv);
		
		IF @exist_Prov IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Proveedor ('+ TRY_CONVERT(nvarchar(10),@CodProv) +') no registrado en el sistema, revise el códido/ID.';
			RETURN;
		END
		
		IF @exist_Prov = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El proveedor de código ('+ TRY_CONVERT(nvarchar(10),@CodProv) +') ya está inactivo';
			RETURN;
		END

		UPDATE Proveedor
		SET EstadoProv = 0,
			DateDelete = SYSDATETIMEOFFSET()
		WHERE CodProv = @CodProv;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al desactivar proveedor.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Proveedor desactivado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
			
		SET @Mensaje = 'Error al desactivar proveedor: ' + ERROR_MESSAGE();
	END CATCH
END