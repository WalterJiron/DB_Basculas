USE Bascula

GO

CREATE PROCEDURE Procs_Eliminar_ProductoAlmacen
    @CodAlmacen INT,
    @CodProd INT,
    @MENSAJE NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar que no sean nulos
        IF @CodAlmacen IS NULL OR @CodProd IS NULL
        BEGIN
            SET @MENSAJE = 'Los campos codigo de Almacen y codigo de Producto son obligatorios.';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia
        DECLARE @Existe BIT;
        SET @Existe = (SELECT EstadoAlmacenProd FROM ProductoAlmacen WITH(UPDLOCK, ROWLOCK)WHERE CodAlmacen = @CodAlmacen AND CodProd = @CodProd);

        IF @Existe IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'El registro no existe en ProductoAlmacen.';
            RETURN;
        END

        IF @Existe = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'El producto ya esta eliminado en este almacen.';
            RETURN;
        END


        UPDATE ProductoAlmacen SET 
			EstadoAlmacenProd = 0,
            DateDelete = SYSDATETIMEOFFSET()
        WHERE CodAlmacen = @CodAlmacen AND CodProd = @CodProd;

        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @MENSAJE = 'No se pudo eliminar el producto del almacen.';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @MENSAJE = 'Producto eliminado correctamente del almacen.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @MENSAJE = 'Error al eliminar producto del almacen: ' + ERROR_MESSAGE();
    END CATCH
END;
