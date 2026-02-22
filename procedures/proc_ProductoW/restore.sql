USE Bascula;

GO

CREATE PROC ProcRestoreProducto
    @CodProd INT,
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar codigo de producto
        IF @CodProd IS NULL
        BEGIN
            SET @Mensaje = 'El código de producto es obligatorio';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado
        DECLARE @EstadoActual BIT;
        DECLARE @NombreProd NVARCHAR(50);
        DECLARE @CodSubCat INT;
        
        SELECT @EstadoActual = EstadoProd,
               @NombreProd = NombreProd,
               @CodSubCat = CodSubCat
        FROM Producto WITH (UPDLOCK, HOLDLOCK)
        WHERE CodProd = @CodProd;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El producto no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El producto ya se encuentra activo';
            RETURN;
        END

        -- Verificar que la subcategoria este activa
        IF NOT EXISTS (
            SELECT 1 FROM SubCategoria WITH (UPDLOCK)
            WHERE CodSubCat = @CodSubCat AND EstadoSubCat = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede recuperar, la subcategoría está inactiva';
            RETURN;
        END

        -- Verificar que el nombre no este siendo usado por otro producto activo
        IF EXISTS (
            SELECT 1 FROM Producto WITH (UPDLOCK)
            WHERE NombreProd = @NombreProd
              AND CodProd <> @CodProd
              AND EstadoProd = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede recuperar, ya existe un producto activo con ese nombre';
            RETURN;
        END

        UPDATE Producto SET
            EstadoProd = 1,
            DateDelete = NULL
        WHERE CodProd = @CodProd;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al recuperar el producto';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Producto recuperado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al recuperar producto: ' + ERROR_MESSAGE();
    END CATCH
END;