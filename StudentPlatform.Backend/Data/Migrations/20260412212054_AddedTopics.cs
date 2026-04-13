using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StudentPlatform.Backend.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddedTopics : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Assignments_Lessons_LessonId",
                table: "Assignments");

            migrationBuilder.DropForeignKey(
                name: "FK_TestQuestions_Lessons_LessonId",
                table: "TestQuestions");

            migrationBuilder.DropForeignKey(
                name: "FK_TestResults_Lessons_LessonId",
                table: "TestResults");

            migrationBuilder.DropTable(
                name: "Lessons");

            migrationBuilder.RenameColumn(
                name: "LessonId",
                table: "TestResults",
                newName: "TopicId");

            migrationBuilder.RenameIndex(
                name: "IX_TestResults_LessonId",
                table: "TestResults",
                newName: "IX_TestResults_TopicId");

            migrationBuilder.RenameColumn(
                name: "LessonId",
                table: "TestQuestions",
                newName: "TopicId");

            migrationBuilder.RenameIndex(
                name: "IX_TestQuestions_LessonId",
                table: "TestQuestions",
                newName: "IX_TestQuestions_TopicId");

            migrationBuilder.RenameColumn(
                name: "LessonId",
                table: "Assignments",
                newName: "TopicId");

            migrationBuilder.RenameIndex(
                name: "IX_Assignments_LessonId",
                table: "Assignments",
                newName: "IX_Assignments_TopicId");

            migrationBuilder.CreateTable(
                name: "Topics",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    SubjectId = table.Column<int>(type: "INTEGER", nullable: false),
                    Title = table.Column<string>(type: "TEXT", nullable: false),
                    Content = table.Column<string>(type: "TEXT", nullable: false),
                    YoutubeUrl = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Topics", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Topics_Subjects_SubjectId",
                        column: x => x.SubjectId,
                        principalTable: "Subjects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Topics_SubjectId",
                table: "Topics",
                column: "SubjectId");

            migrationBuilder.AddForeignKey(
                name: "FK_Assignments_Topics_TopicId",
                table: "Assignments",
                column: "TopicId",
                principalTable: "Topics",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_TestQuestions_Topics_TopicId",
                table: "TestQuestions",
                column: "TopicId",
                principalTable: "Topics",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_TestResults_Topics_TopicId",
                table: "TestResults",
                column: "TopicId",
                principalTable: "Topics",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Assignments_Topics_TopicId",
                table: "Assignments");

            migrationBuilder.DropForeignKey(
                name: "FK_TestQuestions_Topics_TopicId",
                table: "TestQuestions");

            migrationBuilder.DropForeignKey(
                name: "FK_TestResults_Topics_TopicId",
                table: "TestResults");

            migrationBuilder.DropTable(
                name: "Topics");

            migrationBuilder.RenameColumn(
                name: "TopicId",
                table: "TestResults",
                newName: "LessonId");

            migrationBuilder.RenameIndex(
                name: "IX_TestResults_TopicId",
                table: "TestResults",
                newName: "IX_TestResults_LessonId");

            migrationBuilder.RenameColumn(
                name: "TopicId",
                table: "TestQuestions",
                newName: "LessonId");

            migrationBuilder.RenameIndex(
                name: "IX_TestQuestions_TopicId",
                table: "TestQuestions",
                newName: "IX_TestQuestions_LessonId");

            migrationBuilder.RenameColumn(
                name: "TopicId",
                table: "Assignments",
                newName: "LessonId");

            migrationBuilder.RenameIndex(
                name: "IX_Assignments_TopicId",
                table: "Assignments",
                newName: "IX_Assignments_LessonId");

            migrationBuilder.CreateTable(
                name: "Lessons",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Content = table.Column<string>(type: "TEXT", nullable: false),
                    SubjectId = table.Column<int>(type: "INTEGER", nullable: false),
                    Title = table.Column<string>(type: "TEXT", nullable: false),
                    YoutubeUrl = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Lessons", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Lessons_Subjects_SubjectId",
                        column: x => x.SubjectId,
                        principalTable: "Subjects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Lessons_SubjectId",
                table: "Lessons",
                column: "SubjectId");

            migrationBuilder.AddForeignKey(
                name: "FK_Assignments_Lessons_LessonId",
                table: "Assignments",
                column: "LessonId",
                principalTable: "Lessons",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_TestQuestions_Lessons_LessonId",
                table: "TestQuestions",
                column: "LessonId",
                principalTable: "Lessons",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_TestResults_Lessons_LessonId",
                table: "TestResults",
                column: "LessonId",
                principalTable: "Lessons",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
