USE Bascula
GO


CREATE PROC ProcDeleteGarantiaDetalle -- Anulada/vencida
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
		
		IF @exist_Garantia = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La garantía ('+ TRY_CONVERT(varchar(10),@CodGarantia) +') ya ha sido anulada.';
			RETURN;
		END
		
		UPDATE GarantiaDetalle
		SET EstadoGarantia = 0
		WHERE CodGarantia = @CodGarantia;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al anular la vigencia la garantía.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Vigencia de la garantía anulada correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		
		SET @Mensaje = 'Error al anular la vigencia la garantía: ' + ERROR_MESSAGE();
	END CATCH
END