USE Bascula

GO

CREATE PROC ACTIVAR_VENTA
    @CodigoVenta INT,
    @MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF (@CodigoVenta IS NULL)
        BEGIN
            SET @MENSAJE = 'El codigo de la venta es obligatorio';
            RETURN;
        END

        BEGIN TRANSACTION;

        DECLARE @EstadoActual NVARCHAR(15);
		SELECT @EstadoActual = EstadoVenta FROM Venta WITH (UPDLOCK, ROWLOCK) WHERE CodVenta = @CodigoVenta;

        IF (@EstadoActual IS NULL)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'La venta no existe';
            RETURN;
        END

        IF (@EstadoActual <> 'Cancelada')
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'Solo se pueden reactivar ventas canceladas';
            RETURN;
        END

        UPDATE Venta
        SET EstadoVenta = 'registrada',
            FechaVenta = SYSDATETIMEOFFSET()
        WHERE CodVenta = @CodigoVenta;

        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'No se pudo reactivar la venta';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @MENSAJE = 'La venta fue reactivada correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @MENSAJE = 'Error al reactivar la venta: ' + ERROR_MESSAGE();
    END CATCH
END
