using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class FlattenPropertyModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Auctions_ChildProperties_PropertyId",
                table: "Auctions");

            migrationBuilder.DropForeignKey(
                name: "FK_ChatMessages_ChildProperties_PropertyId",
                table: "ChatMessages");

            migrationBuilder.DropForeignKey(
                name: "FK_InstallmentSummaries_ChildProperties_PropertyId",
                table: "InstallmentSummaries");

            migrationBuilder.DropForeignKey(
                name: "FK_PropertyDocs_ChildProperties_PropertyId",
                table: "PropertyDocs");

            migrationBuilder.DropForeignKey(
                name: "FK_PropertyImages_ChildProperties_PropertyId",
                table: "PropertyImages");

            migrationBuilder.DropForeignKey(
                name: "FK_PropertyPriceHistories_ChildProperties_ChildPropertyId",
                table: "PropertyPriceHistories");

            migrationBuilder.DropForeignKey(
                name: "FK_PropertyPriceHistories_ParentProperties_ParentPropertyId",
                table: "PropertyPriceHistories");

            migrationBuilder.DropForeignKey(
                name: "FK_PropertyValuations_ChildProperties_PropertyId",
                table: "PropertyValuations");

            migrationBuilder.DropForeignKey(
                name: "FK_PropertyViews_ChildProperties_PropertyId",
                table: "PropertyViews");

            // Demo data wipe: remove property-linked rows before schema flatten
            migrationBuilder.Sql("""
                DELETE FROM "Bids";
                DELETE FROM "Auctions";
                DELETE FROM "PropertyPriceHistories";
                DELETE FROM "PropertyViews";
                DELETE FROM "PropertyValuations";
                DELETE FROM "PropertyImages";
                DELETE FROM "PropertyDocs";
                DELETE FROM "InstallmentSummaries";
                UPDATE "ChatMessages" SET "PropertyId" = NULL WHERE "PropertyId" IS NOT NULL;
                DELETE FROM "Events" WHERE "PropertyId" IS NOT NULL;
                """);

            migrationBuilder.DropTable(
                name: "ChildProperties");

            migrationBuilder.DropTable(
                name: "ParentProperties");

            migrationBuilder.DropIndex(
                name: "IX_PropertyPriceHistories_ChildPropertyId",
                table: "PropertyPriceHistories");

            migrationBuilder.DropColumn(
                name: "ChildPropertyId",
                table: "PropertyPriceHistories");

            migrationBuilder.RenameColumn(
                name: "ParentPropertyId",
                table: "PropertyPriceHistories",
                newName: "PropertyId");

            migrationBuilder.RenameIndex(
                name: "IX_PropertyPriceHistories_ParentPropertyId",
                table: "PropertyPriceHistories",
                newName: "IX_PropertyPriceHistories_PropertyId");

            migrationBuilder.CreateTable(
                name: "Properties",
                columns: table => new
                {
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: true),
                    ProjectName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    ProjectId = table.Column<Guid>(type: "uuid", nullable: true),
                    Phase = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    FloorNumber = table.Column<int>(type: "integer", nullable: true),
                    UnitNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    ViewType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Orientation = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    DeliveryDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ParkingSlots = table.Column<int>(type: "integer", nullable: true),
                    HasStorageRoom = table.Column<bool>(type: "boolean", nullable: true),
                    BuyingPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: true),
                    BuyingDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Quantity = table.Column<int>(type: "integer", nullable: false),
                    FinishingType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    HasPool = table.Column<bool>(type: "boolean", nullable: false),
                    HasGym = table.Column<bool>(type: "boolean", nullable: false),
                    HasSecurity = table.Column<bool>(type: "boolean", nullable: false),
                    HasParking = table.Column<bool>(type: "boolean", nullable: false),
                    HasPlayground = table.Column<bool>(type: "boolean", nullable: false),
                    HasNannyRoom = table.Column<bool>(type: "boolean", nullable: true),
                    HasDriverRoom = table.Column<bool>(type: "boolean", nullable: true),
                    HasMaidRoom = table.Column<bool>(type: "boolean", nullable: true),
                    HasPrivatePool = table.Column<bool>(type: "boolean", nullable: true),
                    HasRoofAccess = table.Column<bool>(type: "boolean", nullable: true),
                    HasBalcony = table.Column<bool>(type: "boolean", nullable: true),
                    HasGarden = table.Column<bool>(type: "boolean", nullable: true),
                    HasClubhouse = table.Column<bool>(type: "boolean", nullable: true),
                    HasInfrastructure = table.Column<bool>(type: "boolean", nullable: true),
                    HasUndergroundParking = table.Column<bool>(type: "boolean", nullable: true),
                    HasMedicalCenter = table.Column<bool>(type: "boolean", nullable: true),
                    HasCommercialStrip = table.Column<bool>(type: "boolean", nullable: true),
                    HasBusinessHub = table.Column<bool>(type: "boolean", nullable: true),
                    HasOutdoorPools = table.Column<bool>(type: "boolean", nullable: true),
                    HasBicycleLanes = table.Column<bool>(type: "boolean", nullable: true),
                    HasJoggingTrail = table.Column<bool>(type: "boolean", nullable: true),
                    SmartHome = table.Column<bool>(type: "boolean", nullable: true),
                    CentralAC = table.Column<bool>(type: "boolean", nullable: true),
                    NaturalGas = table.Column<bool>(type: "boolean", nullable: true),
                    HasGenerator = table.Column<bool>(type: "boolean", nullable: true),
                    SeaView = table.Column<bool>(type: "boolean", nullable: true),
                    NileView = table.Column<bool>(type: "boolean", nullable: true),
                    PyramidView = table.Column<bool>(type: "boolean", nullable: true),
                    GardenView = table.Column<bool>(type: "boolean", nullable: true),
                    StreetView = table.Column<bool>(type: "boolean", nullable: true),
                    Name = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Description = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    Location = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    ImageUrl = table.Column<string>(type: "text", nullable: false),
                    SquareFeet = table.Column<int>(type: "integer", nullable: false),
                    YearBuilt = table.Column<int>(type: "integer", nullable: false),
                    IsApproved = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Bedrooms = table.Column<int>(type: "integer", nullable: false),
                    Bathrooms = table.Column<int>(type: "integer", nullable: false),
                    Type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Properties", x => x.PropertyId);
                    table.ForeignKey(
                        name: "FK_Properties_Accounts_OwnerId",
                        column: x => x.OwnerId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Properties_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "ProjectId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Properties_OwnerId",
                table: "Properties",
                column: "OwnerId");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_ProjectId",
                table: "Properties",
                column: "ProjectId");

            migrationBuilder.AddForeignKey(
                name: "FK_Auctions_Properties_PropertyId",
                table: "Auctions",
                column: "PropertyId",
                principalTable: "Properties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ChatMessages_Properties_PropertyId",
                table: "ChatMessages",
                column: "PropertyId",
                principalTable: "Properties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_InstallmentSummaries_Properties_PropertyId",
                table: "InstallmentSummaries",
                column: "PropertyId",
                principalTable: "Properties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyDocs_Properties_PropertyId",
                table: "PropertyDocs",
                column: "PropertyId",
                principalTable: "Properties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyImages_Properties_PropertyId",
                table: "PropertyImages",
                column: "PropertyId",
                principalTable: "Properties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyPriceHistories_Properties_PropertyId",
                table: "PropertyPriceHistories",
                column: "PropertyId",
                principalTable: "Properties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyValuations_Properties_PropertyId",
                table: "PropertyValuations",
                column: "PropertyId",
                principalTable: "Properties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyViews_Properties_PropertyId",
                table: "PropertyViews",
                column: "PropertyId",
                principalTable: "Properties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Auctions_Properties_PropertyId",
                table: "Auctions");

            migrationBuilder.DropForeignKey(
                name: "FK_ChatMessages_Properties_PropertyId",
                table: "ChatMessages");

            migrationBuilder.DropForeignKey(
                name: "FK_InstallmentSummaries_Properties_PropertyId",
                table: "InstallmentSummaries");

            migrationBuilder.DropForeignKey(
                name: "FK_PropertyDocs_Properties_PropertyId",
                table: "PropertyDocs");

            migrationBuilder.DropForeignKey(
                name: "FK_PropertyImages_Properties_PropertyId",
                table: "PropertyImages");

            migrationBuilder.DropForeignKey(
                name: "FK_PropertyPriceHistories_Properties_PropertyId",
                table: "PropertyPriceHistories");

            migrationBuilder.DropForeignKey(
                name: "FK_PropertyValuations_Properties_PropertyId",
                table: "PropertyValuations");

            migrationBuilder.DropForeignKey(
                name: "FK_PropertyViews_Properties_PropertyId",
                table: "PropertyViews");

            migrationBuilder.DropTable(
                name: "Properties");

            migrationBuilder.RenameColumn(
                name: "PropertyId",
                table: "PropertyPriceHistories",
                newName: "ParentPropertyId");

            migrationBuilder.RenameIndex(
                name: "IX_PropertyPriceHistories_PropertyId",
                table: "PropertyPriceHistories",
                newName: "IX_PropertyPriceHistories_ParentPropertyId");

            migrationBuilder.AddColumn<Guid>(
                name: "ChildPropertyId",
                table: "PropertyPriceHistories",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ParentProperties",
                columns: table => new
                {
                    ParentPropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uuid", nullable: true),
                    AreaSqm = table.Column<int>(type: "integer", nullable: false),
                    Bathrooms = table.Column<int>(type: "integer", nullable: false),
                    Bedrooms = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    FinishingType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    HasClubhouse = table.Column<bool>(type: "boolean", nullable: false),
                    HasGarden = table.Column<bool>(type: "boolean", nullable: false),
                    HasGym = table.Column<bool>(type: "boolean", nullable: false),
                    HasParking = table.Column<bool>(type: "boolean", nullable: false),
                    HasPlayground = table.Column<bool>(type: "boolean", nullable: false),
                    HasPool = table.Column<bool>(type: "boolean", nullable: false),
                    HasSecurity = table.Column<bool>(type: "boolean", nullable: false),
                    ProjectName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ParentProperties", x => x.ParentPropertyId);
                    table.ForeignKey(
                        name: "FK_ParentProperties_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "ProjectId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "ChildProperties",
                columns: table => new
                {
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: true),
                    ParentPropertyId = table.Column<Guid>(type: "uuid", nullable: true),
                    ProjectId = table.Column<Guid>(type: "uuid", nullable: true),
                    Bathrooms = table.Column<int>(type: "integer", nullable: false),
                    Bedrooms = table.Column<int>(type: "integer", nullable: false),
                    BuyingDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    BuyingPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: true),
                    CentralAC = table.Column<bool>(type: "boolean", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DeliveryDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Description = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    FloorNumber = table.Column<int>(type: "integer", nullable: true),
                    GardenView = table.Column<bool>(type: "boolean", nullable: true),
                    HasBalcony = table.Column<bool>(type: "boolean", nullable: true),
                    HasBicycleLanes = table.Column<bool>(type: "boolean", nullable: true),
                    HasBusinessHub = table.Column<bool>(type: "boolean", nullable: true),
                    HasClubhouse = table.Column<bool>(type: "boolean", nullable: true),
                    HasCommercialStrip = table.Column<bool>(type: "boolean", nullable: true),
                    HasDriverRoom = table.Column<bool>(type: "boolean", nullable: true),
                    HasGarden = table.Column<bool>(type: "boolean", nullable: true),
                    HasGenerator = table.Column<bool>(type: "boolean", nullable: true),
                    HasInfrastructure = table.Column<bool>(type: "boolean", nullable: true),
                    HasJoggingTrail = table.Column<bool>(type: "boolean", nullable: true),
                    HasMaidRoom = table.Column<bool>(type: "boolean", nullable: true),
                    HasMedicalCenter = table.Column<bool>(type: "boolean", nullable: true),
                    HasNannyRoom = table.Column<bool>(type: "boolean", nullable: true),
                    HasOutdoorPools = table.Column<bool>(type: "boolean", nullable: true),
                    HasPrivatePool = table.Column<bool>(type: "boolean", nullable: true),
                    HasRoofAccess = table.Column<bool>(type: "boolean", nullable: true),
                    HasStorageRoom = table.Column<bool>(type: "boolean", nullable: true),
                    HasUndergroundParking = table.Column<bool>(type: "boolean", nullable: true),
                    ImageUrl = table.Column<string>(type: "text", nullable: false),
                    IsApproved = table.Column<bool>(type: "boolean", nullable: false),
                    Location = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Name = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    NaturalGas = table.Column<bool>(type: "boolean", nullable: true),
                    NileView = table.Column<bool>(type: "boolean", nullable: true),
                    Orientation = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    ParkingSlots = table.Column<int>(type: "integer", nullable: true),
                    Phase = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    PyramidView = table.Column<bool>(type: "boolean", nullable: true),
                    Quantity = table.Column<int>(type: "integer", nullable: false),
                    SeaView = table.Column<bool>(type: "boolean", nullable: true),
                    SmartHome = table.Column<bool>(type: "boolean", nullable: true),
                    SquareFeet = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    StreetView = table.Column<bool>(type: "boolean", nullable: true),
                    Type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    UnitNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ViewType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    YearBuilt = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChildProperties", x => x.PropertyId);
                    table.ForeignKey(
                        name: "FK_ChildProperties_Accounts_OwnerId",
                        column: x => x.OwnerId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_ChildProperties_ParentProperties_ParentPropertyId",
                        column: x => x.ParentPropertyId,
                        principalTable: "ParentProperties",
                        principalColumn: "ParentPropertyId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_ChildProperties_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "ProjectId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PropertyPriceHistories_ChildPropertyId",
                table: "PropertyPriceHistories",
                column: "ChildPropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildProperties_OwnerId",
                table: "ChildProperties",
                column: "OwnerId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildProperties_ParentPropertyId",
                table: "ChildProperties",
                column: "ParentPropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildProperties_ProjectId",
                table: "ChildProperties",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_ParentProperties_ProjectId",
                table: "ParentProperties",
                column: "ProjectId");

            migrationBuilder.AddForeignKey(
                name: "FK_Auctions_ChildProperties_PropertyId",
                table: "Auctions",
                column: "PropertyId",
                principalTable: "ChildProperties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ChatMessages_ChildProperties_PropertyId",
                table: "ChatMessages",
                column: "PropertyId",
                principalTable: "ChildProperties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_InstallmentSummaries_ChildProperties_PropertyId",
                table: "InstallmentSummaries",
                column: "PropertyId",
                principalTable: "ChildProperties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyDocs_ChildProperties_PropertyId",
                table: "PropertyDocs",
                column: "PropertyId",
                principalTable: "ChildProperties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyImages_ChildProperties_PropertyId",
                table: "PropertyImages",
                column: "PropertyId",
                principalTable: "ChildProperties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyPriceHistories_ChildProperties_ChildPropertyId",
                table: "PropertyPriceHistories",
                column: "ChildPropertyId",
                principalTable: "ChildProperties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyPriceHistories_ParentProperties_ParentPropertyId",
                table: "PropertyPriceHistories",
                column: "ParentPropertyId",
                principalTable: "ParentProperties",
                principalColumn: "ParentPropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyValuations_ChildProperties_PropertyId",
                table: "PropertyValuations",
                column: "PropertyId",
                principalTable: "ChildProperties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyViews_ChildProperties_PropertyId",
                table: "PropertyViews",
                column: "PropertyId",
                principalTable: "ChildProperties",
                principalColumn: "PropertyId",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
