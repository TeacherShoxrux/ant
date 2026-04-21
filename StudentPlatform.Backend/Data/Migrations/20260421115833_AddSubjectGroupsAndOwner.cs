using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StudentPlatform.Backend.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddSubjectGroupsAndOwner : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CreatedById",
                table: "Subjects",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "SubjectGroups",
                columns: table => new
                {
                    SubjectId = table.Column<int>(type: "INTEGER", nullable: false),
                    GroupId = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SubjectGroups", x => new { x.SubjectId, x.GroupId });
                    table.ForeignKey(
                        name: "FK_SubjectGroups_Groups_GroupId",
                        column: x => x.GroupId,
                        principalTable: "Groups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SubjectGroups_Subjects_SubjectId",
                        column: x => x.SubjectId,
                        principalTable: "Subjects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Subjects_CreatedById",
                table: "Subjects",
                column: "CreatedById");

            migrationBuilder.CreateIndex(
                name: "IX_SubjectGroups_GroupId",
                table: "SubjectGroups",
                column: "GroupId");

            migrationBuilder.AddForeignKey(
                name: "FK_Subjects_Users_CreatedById",
                table: "Subjects",
                column: "CreatedById",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Subjects_Users_CreatedById",
                table: "Subjects");

            migrationBuilder.DropTable(
                name: "SubjectGroups");

            migrationBuilder.DropIndex(
                name: "IX_Subjects_CreatedById",
                table: "Subjects");

            migrationBuilder.DropColumn(
                name: "CreatedById",
                table: "Subjects");
        }
    }
}
