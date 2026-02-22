USE Bascula;

GO

CREATE PROC ProcDeleteDetalleProducto
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
        
        SELECT @EstadoActual = EstadoDetProd
        FROM DetalleProducto WITH (UPDLOCK, HOLDLOCK)
        WHERE CodDetProd = @CodDetProd;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El detalle de producto no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El detalle de producto ya se encuentra eliminado';
            RETURN;
        END

        IF EXISTS(
            SELECT 1
            FROM Producto AS P 
            INNER JOIN DetalleProducto AS DP 
                ON  P.CodProd = DP.CodProd
            WHERE P.EstadoProd = 1 AND DP.CodDetProd = @CodDetProd
        )
         BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El detalle de producto no se puede eliminar porque esta asociado a un producto activo';
            RETURN;
        END

        UPDATE DetalleProducto SET
            EstadoDetProd = 0,
            DateDelete = SYSDATETIMEOFFSET() 
        WHERE CodDetProd = @CodDetProd;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al eliminar el detalle de producto';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Detalle de producto desactivado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al desactivar detalle de producto: ' + ERROR_MESSAGE();
    END CATCH
END;