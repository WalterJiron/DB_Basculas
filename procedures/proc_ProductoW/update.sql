USE Bascula;

GO

CREATE PROC ProcUpdateProducto
    @CodProd INT,
    @NombreProd NVARCHAR(50),
    @DescripProd NVARCHAR(MAX),
    @CodSubCat INT,
    @Stock INT,
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validaciones de campos obligatorios
        IF @CodProd IS NULL OR @NombreProd IS NULL OR @DescripProd IS NULL OR @CodSubCat IS NULL OR @Stock IS NULL
        BEGIN
            SET @Mensaje = 'Todos los campos son obligatorios';
            RETURN;
        END

        -- Validaciones de longitud
        IF LEN(TRIM(@NombreProd)) < 3 OR LEN(TRIM(@NombreProd)) > 50
        BEGIN
            SET @Mensaje = 'El nombre de producto debe tener entre 3 y 50 caracteres';
            RETURN;
        END

        IF LEN(TRIM(@DescripProd)) < 10
        BEGIN
            SET @Mensaje = 'La descripción debe tener al menos 10 caracteres';
            RETURN;
        END

        -- Validacion de stock
        IF @Stock < 0
        BEGIN
            SET @Mensaje = 'El stock no puede ser negativo';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado
        DECLARE @EstadoActual BIT;
        
        SELECT @EstadoActual = EstadoProd
        FROM Producto WITH (UPDLOCK, ROWLOCK)
        WHERE CodProd = @CodProd;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El producto no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El producto se encuentra inactivo';
            RETURN;
        END

        -- Verificar que la subcategoria exista y este activa
        IF NOT EXISTS (
            SELECT 1 FROM SubCategoria WITH (UPDLOCK)
            WHERE CodSubCat = @CodSubCat AND EstadoSubCat = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La subcategoría especificada no existe o está inactiva';
            RETURN;
        END

        -- Verificar nombre unico
        IF EXISTS (
            SELECT 1 FROM Producto WITH (UPDLOCK)
            WHERE NombreProd = TRIM(@NombreProd)
              AND CodProd <> @CodProd
              AND EstadoProd = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Ya existe un producto activo con ese nombre';
            RETURN;
        END

        UPDATE Producto SET
            NombreProd = TRIM(@NombreProd),
            DescripProd = TRIM(@DescripProd),
            CodSubCat = @CodSubCat,
            Stock = @Stock,
            DateUpdate = SYSDATETIMEOFFSET() 
        WHERE CodProd = @CodProd;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al actualizar el producto';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Producto actualizado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Mensaje = 'Error al actualizar producto: ' + ERROR_MESSAGE();
    END CATCH
END;