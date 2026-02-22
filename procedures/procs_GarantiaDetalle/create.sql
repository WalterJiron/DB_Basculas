USE Bascula
GO

CREATE PROC ProcCreateGarantiaDetalle
	@CodDetVenta INT,
	@PlazoMeses INT,
	@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		IF @CodDetVenta IS NULL OR @PlazoMeses IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: El código de detalle de venta y el plazo en meses son obligatorios.';
			RETURN;
		END
		
		IF @PlazoMeses <= 0
		BEGIN
			SET @Mensaje = 'ERROR: El plazo de meses la garantía debe ser mayor a 0.';
			RETURN;
		END
		
		BEGIN TRANSACTION;
		
		DECLARE @exist_DetVenta BIT;
		SET @exist_DetVenta = (SELECT EstadoDetVenta FROM DetalleVenta WITH (UPDLOCK, ROWLOCK)
							   WHERE CodDetVenta = @CodDetVenta);
		
		IF @exist_DetVenta IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Detalle de venta ('+ TRY_CONVERT(varchar(10),@CodDetVenta) +') no encontrado en el sistema, revise su c�digo/ID.';
			RETURN;
		END

		IF @exist_DetVenta = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El detalle de venta del código ('+ TRY_CONVERT(varchar(10),@CodDetVenta) +') se encuentra desactivado.';
			RETURN;
		END

		IF EXISTS (SELECT 1 FROM GarantiaDetalle WITH (UPDLOCK, ROWLOCK)
				   WHERE CodDetVenta = @CodDetVenta
				   AND EstadoGarantia = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El detalle de venta código ('+ @CodDetVenta +') ya tiene otra garantía todavía vigente.';
			RETURN;
		END
		
		INSERT INTO GarantiaDetalle (CodDetVenta, PlazoMeses)
		VALUES (@CodDetVenta, @PlazoMeses);
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al registrar la garantía.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		
		SET @Mensaje = 'Garantía registrada correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		
		SET @Mensaje = 'Error al registrar la garantía: ' + ERROR_MESSAGE();
	END CATCH
END