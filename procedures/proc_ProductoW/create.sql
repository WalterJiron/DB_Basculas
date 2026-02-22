USE Bascula;

GO

CREATE PROC ProcInsertProducto
    @NombreProd NVARCHAR(50),
    @DescripProd NVARCHAR(MAX),
    @CodSubCat INT,
    @Stock INT,
    @Mensaje NVARCHAR(100) OUTPUT,
    @CodProd INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validaciones de campos obligatorios
        IF @NombreProd IS NULL OR @DescripProd IS NULL OR @CodSubCat IS NULL OR @Stock IS NULL
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

        -- Verificar que la subcategoria exista y este activa
        DECLARE @existSubCat AS BIT;
        SET @existSubCat = ( 
            SELECT EstadoSubCat FROM SubCategoria 
            WHERE CodSubCat = @CodSubCat
        )

        IF @existSubCat IS NULL
        BEGIN
            SET @Mensaje = 'EL codigo '+ TRY_CONVERT(nvarchar(20),@CodSubCat) + ' no existe en el sistema';
            RETURN; 
        END

        IF @existSubCat = 0
        BEGIN
            SET @Mensaje = 'La sub categoria '+ TRY_CONVERT(nvarchar(20),@CodSubCat) + ' se encuentra se encunetra inactiva';
            RETURN;
        END

        -- Verificar nombre unico
        IF EXISTS (
            SELECT 1 FROM Producto WITH (UPDLOCK)
            WHERE NombreProd = TRIM(@NombreProd)
              AND EstadoProd = 1
        )
        BEGIN
            SET @Mensaje = 'Ya existe un producto activo con ese nombre';
            RETURN;
        END

        INSERT INTO Producto ( NombreProd, DescripProd, CodSubCat, Stock )
        VALUES (
            TRIM(@NombreProd),
            TRIM(@DescripProd),
            @CodSubCat, @Stock
        );

        SET @Mensaje = 'Producto registrado correctamente';
        
        -- Obtenemos el codigo del producto
        SELECT @CodProd = CodProd
        FROM Producto
        WHERE CodProd = IDENT_CURRENT('Producto');

    END TRY
    BEGIN CATCH
        SET @Mensaje = 'Error al registrar producto: ' + ERROR_MESSAGE();
    END CATCH
END;
