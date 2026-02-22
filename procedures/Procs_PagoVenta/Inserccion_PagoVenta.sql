USE Bascula

GO

CREATE PROCEDURE Proc_Inserccion_Pago_Venta
    @CodPago INT,
    @CodVenta INT,
    @MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar que los códigos no sean nulos
        IF (@CodVenta IS NULL OR @CodPago IS NULL)
        BEGIN
            SET @MENSAJE = 'El código de la venta y el código de pago son campos requeridos.';
            RETURN;
        END

        -- Verificar que la relación no exista ya
        IF EXISTS (SELECT 1 FROM PagoVenta WHERE CodPago = @CodPago AND CodVenta = @CodVenta)
        BEGIN
            SET @MENSAJE = 'La relación entre pago y venta ya existe.';
            RETURN;
        END

        -- Obtener estado actual de la venta
        DECLARE @EstadoActualVenta NVARCHAR(15);
        SET @EstadoActualVenta = (
            SELECT EstadoVenta
            FROM Venta WITH (UPDLOCK, ROWLOCK)
            WHERE CodVenta = @CodVenta
        );

        IF (@EstadoActualVenta IS NULL)
        BEGIN
            SET @MENSAJE = 'El código de la venta no existe.';
            RETURN;
        END

        IF LOWER(TRIM(@EstadoActualVenta)) = 'cancelada'
        BEGIN
            SET @MENSAJE = 'La venta se encuentra cancelada.';
            RETURN;
        END

        -- Obtener estado actual del pago
        DECLARE @EstadoActualPago NVARCHAR(15);
        SET @EstadoActualPago = (
            SELECT EstadoPago
            FROM Pago WITH (UPDLOCK, ROWLOCK)
            WHERE CodPago = @CodPago
        );

        IF (@EstadoActualPago IS NULL)
        BEGIN
            SET @MENSAJE = 'El código del pago no existe.';
            RETURN;
        END

        IF LOWER(TRIM(@EstadoActualPago)) = 'anulado'
        BEGIN
            SET @MENSAJE = 'El pago se encuentra anulado.';
            RETURN;
        END

        -- Insertar la relación
        INSERT INTO PagoVenta (CodPago, CodVenta)
        VALUES (@CodPago, @CodVenta);


        SET @MENSAJE = 'Registrado exitosamente.';
    END TRY
    BEGIN CATCH

        SET @MENSAJE = 'Error al insertar: ' + ERROR_MESSAGE();
    END CATCH
END;
