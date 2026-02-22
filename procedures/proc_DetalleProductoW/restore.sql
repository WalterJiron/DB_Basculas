USE Bascula;

GO

CREATE PROC ProcRestoreDetalleProducto
    @CodDetProd INT,
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar codigo de detalle
        IF @CodDetProd IS NULL
        BEGIN
            SET @Mensaje = 'El código de detalle es obligatorio';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado
        DECLARE @EstadoActual BIT;
        DECLARE @CodProd INT;
        
        SELECT @EstadoActual = EstadoDetProd,
               @CodProd = CodProd
        FROM DetalleProducto WITH (UPDLOCK, HOLDLOCK)
        WHERE CodDetProd = @CodDetProd;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El detalle de producto no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El detalle de producto ya se encuentra activo';
            RETURN;
        END

        -- Verificar que el producto este activo
        IF NOT EXISTS (
            SELECT 1 FROM Producto WITH (UPDLOCK)
            WHERE CodProd = @CodProd AND EstadoProd = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede recuperar, el producto está inactivo';
            RETURN;
        END

        -- Verificar que no exista otro detalle activo para el mismo producto
        IF EXISTS (
            SELECT 1 FROM DetalleProducto WITH (UPDLOCK)
            WHERE CodProd = @CodProd
              AND CodDetProd <> @CodDetProd
              AND EstadoDetProd = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede recuperar, ya existe un detalle activo para este producto';
            RETURN;
        END

        -- Recuperar el detalle
        UPDATE DetalleProducto SET
            EstadoDetProd = 1,
            DateDelete = NULL
        WHERE CodDetProd = @CodDetProd;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al recuperar el detalle de producto';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Detalle de producto recuperado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al recuperar detalle de producto: ' + ERROR_MESSAGE();
    END CATCH
END;