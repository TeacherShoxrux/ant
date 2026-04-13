using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StudentPlatform.Backend.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddedMultipleVideos : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "YoutubeUrl",
                table: "Topics");

            migrationBuilder.CreateTable(
                name: "TopicVideos",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    TopicId = table.Column<int>(type: "INTEGER", nullable: false),
                    Title = table.Column<string>(type: "TEXT", nullable: false),
                    YoutubeUrl = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TopicVideos", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TopicVideos_Topics_TopicId",
                        column: x => x.TopicId,
                        principalTable: "Topics",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TopicVideos_TopicId",
                table: "TopicVideos",
                column: "TopicId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TopicVideos");

            migrationBuilder.AddColumn<string>(
                name: "YoutubeUrl",
                table: "Topics",
                type: "TEXT",
                nullable: false,
                defaultValue: "");
        }
    }
}
