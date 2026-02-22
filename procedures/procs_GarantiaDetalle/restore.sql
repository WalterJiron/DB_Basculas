USE Bascula
GO


CREATE PROC ProcRestoreGarantiaDetalle -- Vigente
	@CodGarantia INT,
	@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		IF @CodGarantia IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Debe proporcionar el código de la garantía.';
			RETURN;
		END
		
		BEGIN TRANSACTION;
		
		DECLARE @exist_Garantia BIT;
		SET @exist_Garantia = (SELECT EstadoGarantia
							   FROM GarantiaDetalle WITH (UPDLOCK, ROWLOCK)
							   WHERE CodGarantia = @CodGarantia);
		
		IF @exist_Garantia IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Garantía ('+ TRY_CONVERT(varchar(10),@CodGarantia) +') no encontrado en el sistema, revise su código/ID.';
			RETURN;
		END
		
		IF @exist_Garantia = 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La garantía ('+ TRY_CONVERT(varchar(10),@CodGarantia) +') ya está activa y sigue vigente.';
			RETURN;
		END
		
		UPDATE GarantiaDetalle
		SET EstadoGarantia = 1
		WHERE CodGarantia = @CodGarantia;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al reactivar la vigencia de la garantía.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Vigencia de la garantía restaurada correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		
		SET @Mensaje = 'Error al restaurar la vigencia de la garantía: ' + ERROR_MESSAGE();
	END CATCH
END