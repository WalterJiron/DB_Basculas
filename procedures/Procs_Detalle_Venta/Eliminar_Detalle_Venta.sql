USE Bascula;

GO

CREATE PROC Eliminar_Detalle_Venta
	@CodDetVenta INT,
	@MENSAJE NVARCHAR(100) OUTPUT 
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF(@CodDetVenta IS NULL)
		BEGIN
			SET @MENSAJE = 'El codigo es un campo obligatorio';
			RETURN;
		END

		BEGIN TRANSACTION;

		DECLARE @Existencia_DetVenta Bit;
		SET @Existencia_DetVenta = (SELECT EstadoDetVenta FROM DetalleVenta WITH(UPDLOCK,ROWLOCK) WHERE CodDetVenta = @CodDetVenta);

		IF(@Existencia_DetVenta IS NULL)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE ='No existe detalle de venta con ese codigo';
			RETURN;
		END

		IF(@Existencia_DetVenta = 0)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE ='El detalle de esta se encuentra inactivo';
			RETURN;
		END

		UPDATE DetalleVenta SET 
			EstadoDetVenta = 0,
			DateDelete = SYSDATETIMEOFFSET()
		WHERE CodDetVenta = @CodDetVenta

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @MENSAJE = 'Error al eliminar el detalle de venta';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @MENSAJE = 'El detalle de venta se elimino correctamente';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

			SET @MENSAJE = 'Error al eliminar el detalle de venta: ' +ERROR_MESSAGE();
	END CATCH
END