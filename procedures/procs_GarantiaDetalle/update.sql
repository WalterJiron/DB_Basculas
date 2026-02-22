USE Bascula
GO


CREATE PROC ProcUpdateGarantiaDetalle
	@CodGarantia INT,
	@CodDetVenta INT,
	@PlazoMeses INT,
	@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		IF @CodGarantia IS NULL OR @CodDetVenta IS NULL OR @PlazoMeses IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: El código de garantía, de detalle de venta y el plazo en meses son obligatorios.';
			RETURN;
		END
		
		IF @PlazoMeses <= 0
		BEGIN
			SET @Mensaje = 'ERROR: El plazo de la garantía debe ser mayor a 0.';
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
			SET @Mensaje = 'ERROR: Garantía ('+ TRY_CONVERT(varchar(10),@CodGarantia) +') no encontrada en el sistema, revise su código/ID.';
			RETURN;
		END

		IF @exist_Garantia = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La garantía ('+ TRY_CONVERT(varchar(10),@CodGarantia) +') se encuentra anulada.';
			RETURN;
		END

		DECLARE @exist_DetVenta BIT;
		SET @exist_DetVenta = (SELECT EstadoDetVenta FROM DetalleVenta WITH (UPDLOCK, ROWLOCK)
							   WHERE CodDetVenta = @CodDetVenta);

		IF @exist_DetVenta IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Detalle de venta ('+ TRY_CONVERT(varchar(10),@CodDetVenta) +') no encontrado en el sistema, revise su código/ID.';
			RETURN;
		END

		IF @exist_DetVenta = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El detalle de venta ´del código ('+ TRY_CONVERT(varchar(10),@CodDetVenta) +') se encuentra desactivado.';
			RETURN;
		END

		IF EXISTS (SELECT 1 FROM GarantiaDetalle WITH (UPDLOCK, ROWLOCK)
				   WHERE CodDetVenta = @CodDetVenta
				   AND CodGarantia <> @CodGarantia
				   AND EstadoGarantia = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Ya existe otra garantía vigente para el detalle de ventas ('+ @CodDetVenta +').';
			RETURN;
		END
		
		UPDATE GarantiaDetalle
		SET CodDetVenta = @CodDetVenta,
			PlazoMeses = @PlazoMeses,
			FechaInicio = CAST(GETDATE() AS DATE)
		WHERE CodGarantia = @CodGarantia;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al actualizar la garantía.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Garantía actualizada correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		
		SET @Mensaje = 'Error al actualizar la garantía: ' + ERROR_MESSAGE();
	END CATCH
END