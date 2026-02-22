USE Bascula
GO

CREATE PROC ProcDeleteDetalleCompra
@CodDetCompra INT,
@CodCompra INT,
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodDetCompra IS NULL OR @CodCompra IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Debe proporcionar el código de la compra y de su detalle correspondiente.';
			RETURN;
		END
		
		DECLARE @exist_DetCompra BIT;
        SET @exist_DetCompra = (SELECT EstadoDetCompra 
								FROM DetalleCompra WITH (UPDLOCK, ROWLOCK)
								WHERE CodDetCompra = @CodDetCompra);
		
		IF @exist_DetCompra IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Código de Detalle de compra ('+ TRY_CONVERT(nvarchar(10),@CodDetCompra) +') no registrado en el sistema, revise el código/ID.';
			RETURN;
		END
		
		IF @exist_DetCompra = 0
		BEGIN
			SET @Mensaje = 'ERROR: El detalle de compra del código ('+ TRY_CONVERT(nvarchar(10),@CodDetCompra) +') ya está inactivo.';
			RETURN;
		END

		DECLARE @exist_Compra NVARCHAR(15) = (SELECT EstadoCompra FROM Compra WITH (UPDLOCK, ROWLOCK)
											  WHERE CodCompra = @CodCompra);

		IF @exist_Compra IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Código de Compra ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') no encontrada en el sistema, revise el código/ID.';
			RETURN;
		END

		IF NOT EXISTS (SELECT 1 FROM DetalleCompra WITH (UPDLOCK, ROWLOCK)
					   WHERE CodCompra = @CodCompra
					   AND CodDetCompra = @CodDetCompra)
		BEGIN
			SET @Mensaje = 'ERROR: El código de compra ('+ TRY_CONVERT(nvarchar(10),@CodCompra) +') no coincide con la compra del detalle ('+ TRY_CONVERT(nvarchar(10),@CodDetCompra) +').';
			RETURN;
		END

		UPDATE DetalleCompra
		SET EstadoDetCompra = 0,
			DateDelete = SYSDATETIMEOFFSET()
		WHERE CodDetCompra = @CodDetCompra AND CodCompra = @CodCompra;
		
		SET @Mensaje = 'Detalle de compra desactivado correctamente.';
	END TRY
	BEGIN CATCH
		SET @Mensaje = 'Error al desactivar detalle de compra: ' + ERROR_MESSAGE();
	END CATCH
END