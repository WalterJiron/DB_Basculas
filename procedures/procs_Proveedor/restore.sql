USE Bascula
GO

CREATE PROC ProcRestoreProveedor
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
		
		IF @exist_Prov = 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El proveedor del código ('+ TRY_CONVERT(nvarchar(10),@CodProv) +') ya está activo';
			RETURN;
		END

		UPDATE Proveedor
		SET EstadoProv = 1,
			DateDelete = NULL
		WHERE CodProv = @CodProv;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al reactivar proveedor.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Proveedor reactivado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
			
		SET @Mensaje = 'Error al reactivar proveedor: ' + ERROR_MESSAGE();
	END CATCH
END